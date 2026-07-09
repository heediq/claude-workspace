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

Not started yet — blocked on `feature/rbac-frontend-ui-api` landing `GET /me`'s
`effectivePermissions` and `GET /api/v1/users` (can build kit primitives in parallel; screens need the
API changes).

## Resume point
Branch created, no commits yet. Next: start with Step 3 (kit primitives, no API dependency) while
`feature/rbac-frontend-ui-api` Step 1 lands, then Steps 2/4/5.
