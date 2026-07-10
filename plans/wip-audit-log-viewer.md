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
- **Step 3 (heediq-web) — in progress.** Branch created off `develop`, no commits yet.

**Next immediate action:** Build Step 3 — `src/routes/AuditLogPage.tsx` (table + filters +
`useInfiniteQuery`, loading/error/empty branches matching `UsersPanel.tsx`), new `/org/audit-log`
route in `App.tsx`, a `<Can permission="audit:read">` card in `SettingsPage.tsx`, i18n keys, and
`AuditLogPage.test.tsx`. See the plan file for full detail.

**Open questions / risks:** None currently — Steps 1 and 2's designs are confirmed working
independently. Step 3 depends on nothing further from Steps 1/2 merging (it calls the API by path;
the route works against a locally-run `heediq-api` regardless of PR-merge state).
