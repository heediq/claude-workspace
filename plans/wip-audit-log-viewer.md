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
- **Step 2 (heediq-api) — not started.** Branch created off `develop`, no commits.
- **Step 3 (heediq-web) — not started.** Branch created off `develop`, no commits.

**Next immediate action:** Build Step 2 — new `src/routes/audit-log.ts` (`GET /` gated by
`requirePermission('audit:read')`, mounted as `v1.route('/org/audit-log', auditLogRouter)` in
`src/app.ts`). See the plan file for the exact query strategy (base-table query vs. `by-user` GSI
query when `actorUserId` filter present, cursor pagination matching `sources.ts`'s pattern) and test
list (`src/__tests__/audit-log.test.ts`, mocked `dynamo.send`, same harness as `roles.test.ts`).

**Open questions / risks:** None currently — Step 1's design (narrow `Query` grant, no `Scan`) is
confirmed working. Step 2 depends on nothing further from Step 1 merging (the grant only matters at
deploy time, not for local dev against mocked DynamoDB).
