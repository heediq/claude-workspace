# WIP — D-102 Phase 5: audit-log viewer

**Branches:** `feature/audit-log-viewer-infra` (heediq-infra), `feature/audit-log-viewer-api`
(heediq-api, created, no commits yet), `feature/audit-log-viewer-web` (heediq-web, created, no
commits yet).

**Goal:** `GET /org/audit-log` (cursor-paginated, filterable by date range/actor/action/resource
type, gated by `audit:read`) in `heediq-api`, plus a `/org/audit-log` viewer page in `heediq-web`.
Full plan: `/Users/andriiperevoznyi/.claude/plans/vast-brewing-wigderson.md` (3 steps: infra grant →
API route → web page).

**State:**
- **Step 1 (heediq-infra) — done, PR open.** `lib/api/api-stack.ts`: added
  `auditLogTable.grant(apiFn, 'dynamodb:Query')` alongside the existing `grantWriteData` (GetItem/Scan
  still blocked). Updated `test/api-stack.test.ts`'s audit-log IAM test to match (also corrected an
  inaccurate claim in the old test/comment — `grantWriteData` always included Update/Delete at the
  IAM layer; write-once is an app-code guarantee only, not an IAM one). `npm run build` clean, full
  suite 177/177 green. Committed `9c8f27a`, pushed, PR:
  [heediq-infra#51](https://github.com/heediq/heediq-infra/pull/51) (not yet merged).
- **Step 2 (heediq-api) — done, PR open.** New `src/routes/audit-log.ts` (`GET /` gated by
  `requirePermission('audit:read')`), mounted as `v1.route('/org/audit-log', auditLogRouter)` in
  `src/app.ts`. Base-table query by default; `by-user` GSI + `orgId` re-assertion when `actorUserId`
  filter given; cursor pagination matches `sources.ts`. 7 new tests in
  `src/__tests__/audit-log.test.ts` (mocked `dynamo.send`). `npm run typecheck` clean, full suite
  167/167 green. Committed `62a7012`, pushed, PR:
  [heediq-api#27](https://github.com/heediq/heediq-api/pull/27) (not yet merged).
- **Step 3 (heediq-web) — done, PR open.** New `src/routes/AuditLogPage.tsx` (filterable/paginated
  table gated by `<Can permission="audit:read">`, "Load more" driven by `nextCursor`), `/org/audit-log`
  route in `App.tsx` (falls back to `/settings` if ungated), a matching card on `SettingsPage.tsx`,
  new `auditLog.*`/`nav.auditLog` i18n keys. 5 new tests in
  `src/routes/__tests__/AuditLogPage.test.tsx` (mocked `apiClient`). `npm run test:pre-pr` 164/164
  green. Committed `24d92b1`, pushed, PR:
  [heediq-web#27](https://github.com/heediq/heediq-web/pull/27) (not yet merged).

**All 3 steps done — PRs open, none merged yet.** Next actions once merged (in dependency order:
infra#51 → api#27 → web#27): run the manual QA scenarios from the plan file (org admin
filter/pagination, org member sees no entry point + gets redirected, cross-org isolation via
`actorUserId`), then Step 5 (README updates — `heediq-api/README.md`'s stale "write-only, no route
reads it back yet" gotcha, `heediq-web/README.md`) and Step 6 (memory actualization: mark this
phase `Done` in `wip-rbac-audit-trail.md`, delete this file, update D-102's `Related code` pointer).

**Open questions / risks:** None currently. Manual QA and the write-only-gotcha README fix are
blocked on all three PRs merging and a deploy to `dev`, not on any further local work.
