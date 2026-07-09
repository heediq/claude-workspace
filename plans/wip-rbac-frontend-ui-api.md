# WIP — D-102 Phase 4: Frontend RBAC UI (heediq-api half)

**Branch:** `feature/rbac-frontend-ui-api` in `heediq-api`, off `develop` (Phase 3 merged `0efb7eb`).

**Design reference:** `memory/business/DECISIONS.md` D-102/D-105 · phase index
`plans/wip-rbac-audit-trail.md` · full plan `/Users/andriiperevoznyi/.claude/plans/soft-shimmying-volcano.md`.

**Companion branch:** `feature/rbac-frontend-ui` in `heediq-web` (`wip-rbac-frontend-ui-web.md`) —
depends on this branch's `GET /me` + `GET /api/v1/users` changes.

## Plan
1. `src/routes/me.ts` — add `effectivePermissions: c.get('permissions')` to the response.
2. New `src/routes/users.ts` — `GET /api/v1/users`, org-scoped `Query` on `heediq-users`, returns
   `{ users: User[] }`. Register in `src/app.ts` as `v1.route('/users', usersRouter)`.
3. `src/routes/sources.ts` — migrate `GET /` off `role === 'member'` onto
   `!c.get('permissions').includes('sources:read')` for the own-sources-only filter.
4. Tests: extend `me.test.ts`, new `users.test.ts` (cross-org isolation + empty-org), extend
   `sources.test.ts` (custom role with only `sources:read-own` scopes like `member` does today).
5. `pnpm run test:pre-pr` green.
6. Docs: `heediq-api/README.md` — endpoints table + D-102/D-105 paragraph + test count.

Steps 1–2 done and committed (`7c194bd`): `GET /me` `effectivePermissions`, new `GET /api/v1/users`,
`sources.ts` migrated off `role === 'member'`, all with tests. `pnpm run test:pre-pr` green
(typecheck + 160/160 unit).

## Resume point
Done, committed, pushed, PR open: Steps 1–2 (`7c194bd`), README update (`5608311`).
`pnpm run test:pre-pr` green (typecheck + 160/160 unit). PR:
https://github.com/heediq/heediq-api/pull/26 (base `develop`). Nothing remaining on this branch.
