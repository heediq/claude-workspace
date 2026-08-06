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

- **Phase D — `heediq-web` E2E Tier 1** ✅ built on branch, all green, **not yet PR'd** (awaiting
  the user's go-ahead to commit/push — workspace rule: commit only when asked). Built as one branch
  per the user's "everything in one branch" choice.
  - **Production seam (the one prod-source change)**: `src/lib/auth/e2e-seam.ts` — `readE2eSession()`
    returns `window.__E2E_SESSION__` only when `import.meta.env.VITE_E2E` is set (statically
    dead-code-eliminated in real builds). `AuthContext.tsx` bootstraps from it at mount, before the
    refresh-token branch. Guard unit tests: `e2e-seam.test.ts` (3 — incl. the D-155 "seam absent
    unless VITE_E2E" assertion: returns null even with a planted blob when the flag is unset) +
    an `AuthContext.test.tsx` case (planted session boots authenticated, skips the refresh round trip).
  - **Config/wiring**: `playwright.flows.config.ts` (`testDir e2e/flows`, port 5273, Chromium,
    webServer `pnpm dev` with `VITE_E2E=1` + dummy API/WS/Amplitude env); `playwright.config.ts`
    gains `testIgnore '**/flows/**'` so the responsive harness and flow tier never collide;
    `package.json` `test:e2e` script.
  - **Harness** `e2e/support/`: `test.ts` (extends base with `persona` option + `api`/`analytics`
    fixtures, overrides `page` to install auth + WS fakes; re-exports `emitWs`); `auth.ts`
    (`PERSONAS` admin/member/custom/crossOrg, `makeIdToken`, `plantSession` via `addInitScript`);
    `api.ts` (`ApiMock` route-mocking `**/api/v1/**`, `on`/`onError`, unmatched → `404 E2E_UNMOCKED`);
    `ws.ts` (fake `window.WebSocket` + `emitWs`); `amplitude.ts` (regex route-mock of `*.amplitude.com`
    — POST batch capture with gzip/deflate/brotli decode, GET remote-config stub — `waitForEvent`
    asserting `user_id` on track events, `waitForGroup` for the `org` group which rides on `$identify`);
    `ids.ts` (fixed UUIDs).
  - **Fixtures** `e2e/fixtures/`: `me.ts` (`GET /me` per persona, the D-102 `<Can>` authority) +
    `domain.ts` (source/extractedItem/context/contextTree/conversation/chatMessage), every builder
    `parse`d through `@heediq/shared` so a drifted fixture fails at construction.
  - **Flows** `e2e/flows/` — 6 tests / 5 files, all 7 journeys, all green: `login-identity`,
    `capture-review` (capture→WS classification→review→file, full D-154 funnel), `context-chat`
    (library open + chat send, ×2), `rbac-settings` (admin sees + opens audit log; member sees no
    admin cards + is redirected from `/org/audit-log` → `/settings`, ×2).
  - `e2e/README.md` documents both tiers + how to write a flow. CI: new `e2e` job in
    `.github/workflows/ci.yml` (installs Chromium `--with-deps`, runs `pnpm test:e2e`) alongside the
    existing typecheck/test job, on PRs to develop/main.
  - Full suite green: unit 346/346, typecheck clean, `pnpm test:e2e` 6/6.

- **Phase D — E2E Tier 1 (mocked browser Playwright)** ❌ DROPPED by D-156 (2026-08-06).
  Was built + green on `heediq-web` branch `feature/e2e-tier1-flows`; the user rejected the mocked/
  per-PR design. PR #53 **closed, not merged** (recoverable on the remote branch); the CI-on-PR `e2e`
  job was reverted on `develop`. See the D-156 supersession.

- **Phase E → recast as the D-156 build (E2E, single full real-backend suite)** ✅ built on branch
  `feature/e2e-real-backend-d156` (heediq-api), awaiting user go-ahead to commit/PR:
  - `tests/e2e/lib/auth.mjs` — shared `resolveIdToken()` (ID_TOKEN/TOKEN_FILE override else Cognito
    `USER_PASSWORD_AUTH` provision from a seeded dev user; no AWS creds). Verbatim-copied into
    `heediq-chat/tests/e2e/lib/auth.mjs` (separate repo). Closes the D-147 shared-helper backlog item.
  - `tests/e2e/full-loop-smoke.mjs` + `heediq-chat/.../chat-smoke.mjs` refactored onto the helper.
  - `tests/e2e/audio-smoke.mjs` — NEW opt-in GPU transcription-path smoke (presign→S3 PUT→jobs→Whisper
    →summarization; synth tone WAV, asserts terminal `done`/`ready`, not wording). `pnpm e2e:audio`.
  - `package.json`: `e2e` (=full-loop, gate default) + `e2e:audio`.
  - `.github/workflows/deploy.yml`: `e2e` job on `main` only, runs `pnpm e2e` against the dev stack
    (SSM `/heediq/api/{endpoint-url,ws-endpoint-url,cognito-client-id}`, `E2E_TEST_USER_*` secrets);
    `deploy-staging` now `needs: [build, e2e]`.
  - `tests/e2e/README.md` rewritten for D-156. All scripts `node --check` clean; YAML valid.

## Next
**Phases A–C are done, merged to `develop`, and deployed to dev with server analytics live**
(2026-08-06). The D-154 analytics story is end-to-end in dev: client taxonomy emitting, server
choke-point emitting the 3 backend-truth events, both against one Amplitude project via the shared
`/heediq/analytics/amplitude-api-key` key. Staging/prod remain opt-out (no `-c analytics=true`, param
not yet provisioned there) — enable deliberately when ready.

**E2E was re-scoped by D-156**: the D-155 mocked browser tier (Phase D) is dropped; the single full
real-backend suite is built on `feature/e2e-real-backend-d156` (heediq-api + a helper copy in
heediq-chat). Immediate next action: **commit + open the D-156 PR when the user asks** (workspace
rule: no commit/PR until requested; PRs via `gh`, no local merge to develop).

**Two things need infra/ops setup before the gate is green in CI** (owed, not code):
1. A seeded, CONFIRMED dev test user with a permanent password + `E2E_TEST_USER_EMAIL` /
   `E2E_TEST_USER_PASSWORD` GitHub secrets in the `dev` environment.
2. The Cognito app client (`/heediq/api/cognito-client-id`) must have `USER_PASSWORD_AUTH` enabled, and
   `AWS_DEPLOY_ROLE_DEV` must permit `ssm:GetParameter` on the three params.

**Validation still owed in Amplitude UI** (post-deploy, external — can't be scripted here): confirm a
server `source_processing_completed {sourceId}` joins a client `capture_started {sourceId}` under one
`user_id` in the `org` group, end-to-end through a real dev capture.

## Open questions / risks
- The E2E gate proves `main` HEAD against the **dev** stack — correct only while promotion is a
  develop→main fast-forward (dev already runs that code). If a hotfix lands on `main` ahead of dev,
  the gate would test stale code; revisit if the hotfix flow (D-049) diverges from that assumption.
- k6 stress-test wiring still pending (was always separate from the E2E tiers).
- No blockers currently.
