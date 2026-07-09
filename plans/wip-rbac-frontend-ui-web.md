# WIP — D-102 Phase 4: Frontend RBAC UI (heediq-web half)

**Branch:** `feature/rbac-frontend-ui` in `heediq-web`, off `develop` (`4fa79b6`).

**Design reference:** `memory/business/DECISIONS.md` D-102/D-105 · phase index
`plans/wip-rbac-audit-trail.md` · full plan `/Users/andriiperevoznyi/.claude/plans/soft-shimmying-volcano.md`.

**Companion branch:** `feature/rbac-frontend-ui-api` in `heediq-api` (`wip-rbac-frontend-ui-api.md`) —
this branch depends on its `GET /me` `effectivePermissions` field and new `GET /api/v1/users`.

## Plan
1. Bump `@heediq/shared` `^0.8.0` → `^0.10.0` in `package.json`.
2. `src/lib/rbac/types.ts`, `usePermissions.ts`, `Can.tsx`, `README.md` — permission-aware UI wrappers
   sourced from `GET /me`'s `effectivePermissions` (never client-side JWT decode).
3. New UI-kit primitives: `Table`, `Modal`, `Checkbox`, `Select` under `src/components/ui/` — each
   with README + gallery entry in `DevUiGalleryPage.tsx` + full state coverage.
4. `src/routes/RolesSettingsPage.tsx` + `src/features/rbac/RoleForm.tsx`/`GroupForm.tsx` — role/group
   CRUD screens at new route `/settings/roles`, gated by `<Can permission="org:manage-roles">`, linked
   from `SettingsPage`.
5. User assignment panel (within `RolesSettingsPage` or a `Users` tab) — lists `GET /api/v1/users`,
   assign/remove via `/users/:userId/role-assignments`.
6. Tests per component/screen; `pnpm run test:pre-pr` green.
7. Docs: `heediq-web/README.md` — new Key Files, route, dependency bump, test count.

Step 3 done and committed (`4cb290a`): `@heediq/shared` bumped to `0.10.0` (no type-shape drift —
full suite green), `src/lib/rbac/` (`types.ts`, `usePermissions.ts`, `Can.tsx`, `README.md`, tests).
`GetMeResponse` moved out of `SettingsPage.tsx` into the shared `types.ts`. Companion `heediq-api`
branch's `GET /me` `effectivePermissions` + `GET /api/v1/users` are also done (`7c194bd`), so screens
in Steps 5/6 are now unblocked.

Step 4 done and committed (`8e031d3`): `Table`, `Modal`, `Checkbox`, `Select` kit primitives (Radix
Dialog/Checkbox/Select-based), each with README + test + gallery entry in `DevUiGalleryPage.tsx`,
exported from `src/components/ui/index.ts`. `pnpm run test:pre-pr` green (typecheck + 128/128 unit).

Step 5 done: `Toast` primitive, `RolesPanel`/`GroupsPanel`/`RoleForm`/`GroupForm`/
`RolesSettingsPage.tsx` (`/settings/roles` route, `<Can permission="org:manage-roles">`-gated, nav
link wired). Step 6 done: `UsersPanel`/`AssignmentsModal` (per-user lazy-fetched assignments,
assign/remove flows), `rolesSettings.users.*`/`rolesSettings.tabs.users` i18n keys, tests for both.
Caught and fixed a real `Select` controlled/uncontrolled bug at the kit-primitive level
(`src/components/ui/Select/Select.tsx` — `value={value ?? ''}`) while writing the assign-flow tests.
`pnpm run test:pre-pr` green (typecheck + 158/158 unit, 38 files). Step 7 README update done
(`heediq-web/README.md` — Key Files, Dependencies, Testing sections, test count 24/107→38/158).

## Resume point
Done, committed, pushed, PR open: Toast primitive + Select controlled/uncontrolled fix (`fb8f326`),
RBAC screens (`aa75d3d`), README update (`4754e2c`) on top of Step 3/4's `4cb290a`/`8e031d3`, plus a
follow-up permission↔i18n drift-coverage test (`76508dc`). `pnpm run test:pre-pr` green (typecheck +
159/159 unit, 39 files). PR: https://github.com/heediq/heediq-web/pull/26 (base `develop`). Nothing
remaining on this branch.
