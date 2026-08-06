# WIP — Wide E2E coverage + analytics taxonomy & cross-service correlation (D-154, D-155)

**Goal**: broaden product analytics from the D-151 6-event funnel to the full D-154 taxonomy
(~35 client events + a server choke-point + cross-service identity via `accountId`/`orgId`), and add
a mocked-backend Playwright E2E tier (D-155 Tier 1) covering every authed flow, alongside the
existing D-147 real-stack smokes (Tier 2). Full plan:
`/Users/andriiperevoznyi/.claude/plans/lovely-snacking-flame.md`. Decisions locked in
`memory/business/DECISIONS_FULL.md` (D-154, D-155).

This spans multiple repos/branches — tracked here as one initiative, one phase at a time.

## State by phase

- **Phase A — `heediq-shared`** ✅ done, merged, published.
  `heediq-shared/src/analytics.ts` (id-prop types + cross-service event names + `buildAnalyticsEvent`
  builder). Merged to `develop`, version-bumped, merged to `main`, published as
  `@heediq/shared@0.15.6` on GitHub Packages.

- **Phase B — `heediq-web` client taxonomy** ✅ done, merged to `develop` + deployed to dev
  (2026-08-06, squash-merged from `feature/analytics-taxonomy`).
  - `EventMap` extended from 8 → ~38 events across auth/identity, capture/source, review, context
    library, chat, ledger, rbac, audit/settings/pwa. `identifyUser` now sets an Amplitude `org` group
    (`setGroup('org', orgId)`) alongside `setUserId(accountId)`.
  - `AnalyticsBridge.tsx` extended: `chat_complete` → `chat_response_received`, `ledger_ready` →
    `ledger_reconciled` (alongside the existing `classification_ready` → `source_ready`).
  - `track()` call sites wired across ~20 files (HomePage, AuthCallbackPage, SettingsPage,
    SettingsLinkCallbackPage, VerifyAndSetPasswordForm, the 3 ingest forms, SourceDetailPage,
    ReviewWizardPage, CreateContextModal, ContextDetailPanel, ChatThread, LedgerSection, RolesPanel,
    GroupsPanel, AssignmentsModal, AuditLogPage, useInstallPrompt, AuthContext).
  - Fixed a bug found during this work: `AuthCallbackPage`'s new `providerFromIdToken` crashed on a
    non-JWT id token (broke a pre-existing test); wrapped in try/catch so a malformed token just
    skips the `login_succeeded {method}` track call instead of failing the whole OAuth callback.
  - Unit tests added: org-group set/skip, a representative per-domain `it.each` over the new events,
    and a structural D-093 denylist guard that scans the `EventMap` source text (via Vite's `?raw`
    import — no `node:fs`/`__dirname`, heediq-web has no `@types/node`) for
    `email`/`transcript`/`message`/`title`/`password`/`token`/`secret` keys.
  - `src/lib/analytics/README.md` rewritten with the full taxonomy table + correlation model +
    acknowledged gaps.
  - `pnpm test:pre-pr` green: 74 files / 342 tests passed, typecheck clean.
  - **Acknowledged gaps (deferred, no UI yet)**: `source_deleted`, `context_archived`,
    `context_grant_created`, and group (as opposed to role) assignment tracking in
    `AssignmentsModal.tsx`. Not yet added to `BACKLOG.md` — do that before/at PR time.

- **Phase C — `heediq-api` + `heediq-infra` server choke-point** ✅ done, merged to `develop` +
  **deployed to dev with server analytics enabled** (2026-08-06). Merge order was infra → api → web,
  each dev deploy watched green; verified `AMPLITUDE_API_KEY` is set on exactly the 3 emitters
  (ws-status-pusher, auth-provision, auth-trigger-post-authentication) and absent on the non-emitters
  (e.g. pre-signup) in the dev account.
  - `heediq-api/src/lib/analytics.ts` — `emitServerAnalytics` wraps `@heediq/shared`'s
    `buildServerAnalyticsEvent` around the Amplitude Node HTTP V2 SDK (`@amplitude/analytics-node`,
    new dep, bundled into the emitting handler bundles). Fail-safe & latency-bounded: no key → clean
    no-op; `init` cached; build/`track` errors caught + logged, never rethrown; post-`track` flush
    bounded by an 800 ms `Promise.race` so a stalled endpoint can't hold a Lambda open. Maps
    `user_id = accountId` (D-099), `groups: { org: orgId }`, deterministic `insert_id`, `time`,
    id/enum/count-only props (D-093).
  - Emit sites (chosen over the plan's original `classification-pusher` for the source event, since
    only the jobs pusher has `jobId` + terminal status + a cheap `userId` lookup):
    `source_processing_completed {sourceId, jobId, status}` from `ws-pusher.ts` on terminal
    `done`/`failed` (read-only `heediq-sources` Get for the uploader's `userId`);
    `user_provisioned {tier:'free'}` from `auth-provision.ts` first-login branch;
    `login_completed {method}` from `auth-trigger-post-authentication.ts` (fires only on real auth,
    not refresh; skips first login — the user row doesn't exist yet, covered by `user_provisioned`).
  - `heediq-infra`: `lib/shared/analytics-env.ts` — `amplitudeApiKeyEnv(scope)` gates
    `AMPLITUDE_API_KEY` on `-c analytics=true` (opt-in per env), resolving SSM
    `/heediq/analytics/amplitude-api-key` **at deploy** (value baked into the env — auth path never
    does a runtime SSM read). This is a **shared neutral param** (not `/heediq/web/` or `/heediq/api/`)
    — the same Amplitude project key `heediq-web` bakes into `VITE_AMPLITUDE_API_KEY`, so client +
    server events land in one project and the D-154 cross-service join resolves. The dev deploy passes
    `-c analytics=true`; staging/prod stay opt-out until deliberately enabled. Wired onto exactly the
    3 emitters (WS pusher + AuthProvisionFn + PostAuthenticationFn), plus
    `sourcesTable.grantReadData(pusherFn)` + `SOURCES_TABLE_NAME`. Absent flag → no env, deploy
    unchanged (infra-first, D-050).
  - Gotcha found: the shared `AnalyticsIdentitySchema` validates `orgId` as a **UUID** at runtime
    though the `.d.ts` widens it to `string` — a non-UUID `orgId` makes the builder throw (caught →
    event dropped). All emit sites pass the real `custom:orgId` UUID; tests use a valid-UUID fixture.
  - Tests: `heediq-api` 309/309 (8 helper + handler emit assertions); `heediq-infra` 237/237 (5 new
    in `test/analytics-env.test.ts` pinning the flag-gated wiring on/off both stacks). Typecheck clean
    both repos; both stacks `cdk synth` clean with and without the flag; all 3 handler bundles build
    with Amplitude inlined (~590 KB).

- **Phase D — `heediq-web` E2E Tier 1** ⬜ not started.
  `playwright.flows.config.ts` (`VITE_E2E=1`) + `pnpm test:e2e`; `e2e/support/` (auth fixture via
  synthetic unsigned JWT + a DEV/E2E-gated `VITE_E2E` seam, fake WS `__wsEmit`, Amplitude ingestion
  route-mock/capture); `e2e/fixtures/` (API mocks parsed through `@heediq/shared` Zod schemas);
  `e2e/flows/*.e2e.ts` per journey (login/identity, capture→processing→review→filing, Context
  Library, chat, RBAC, audit log, settings) each asserting UI outcome + fired D-154 analytics events;
  `e2e/README.md`; wire into CI-on-PR.

- **Phase E — E2E Tier 2 extensions** ⬜ not started.
  Audio/transcription-path dev-smoke + shared token-provisioning helper, alongside the existing D-147
  chat + full-loop smokes.

## Next
**Phases A–C are done, merged to `develop`, and deployed to dev with server analytics live**
(2026-08-06). The D-154 analytics story is end-to-end in dev: client taxonomy emitting, server
choke-point emitting the 3 backend-truth events, both against one Amplitude project via the shared
`/heediq/analytics/amplitude-api-key` key. Staging/prod remain opt-out (no `-c analytics=true`, param
not yet provisioned there) — enable deliberately when ready.

Immediate next action: **Phase D — E2E Tier 1** (`heediq-web` mocked-backend Playwright suite, D-155).
Not started. Then Phase E (Tier 2 smoke extensions).

**Validation still owed in Amplitude UI** (post-deploy, external — can't be scripted here): confirm a
server `source_processing_completed {sourceId}` joins a client `capture_started {sourceId}` under one
`user_id` in the `org` group, end-to-end through a real dev capture.

## Open questions / risks
- Phase C needs a new `@amplitude/analytics-node` dependency and an SSM param in `heediq-infra` —
  infra-first deploy order (D-050) applies.
- The `VITE_E2E` auth seam (Phase D) must be gated strictly to non-prod builds — plan calls for a unit
  test asserting the seam is absent unless `VITE_E2E` is set.
- No blockers currently; each phase is independently shippable per the plan.
