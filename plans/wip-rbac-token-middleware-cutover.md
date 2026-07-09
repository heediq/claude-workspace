# WIP — D-102 Phase 3: RBAC token/middleware cutover

**Branches:** `feature/rbac-token-middleware-cutover` in both `heediq-infra` and `heediq-api` (no
`heediq-shared` change needed — the Permission catalog/schemas already exist from Phase 1).

**Design reference:** `memory/business/DECISIONS.md` D-102 · phase index
`plans/wip-rbac-audit-trail.md` · full architecture in `memory/business/architecture.md` §"RBAC &
Audit Trail" (intentionally left stale until all 5 phases ship).

## Plan (approved)
1. `heediq-infra`: add `by-group` sparse GSI to `heediq-role-assignments`; add
   `custom:permissions` (String)/`custom:rbacVersion` (Number) Cognito custom attributes. **Done** —
   `tables.ts`, `cognito.ts`, tests in `test/foundation/tables.test.ts` +
   `test/foundation/cognito.test.ts`, `test:pre-pr` green (177 tests).
2. `heediq-api`: new `src/lib/rbac.ts` — `ensureOrgRbacSeeded`, `ensureUserRoleAssignment`,
   `resolveEffectivePermissions`, `bumpRbacVersion(ForRole/ForGroup)`. **Not started.**
3. `heediq-api`: `auth-provision.ts` stamps `custom:permissions`/`custom:rbacVersion` on every
   claims-issuing branch; new-org path seeds roles + admin assignment. **Not started.**
4. `heediq-api`: new `src/middleware/rbac.ts` — `requirePermission(permission)`, checks
   `rbacVersion` freshness against `heediq-users`, 401 `RBAC_STALE` on mismatch. **Not started.**
5. `heediq-api`: `roles.ts`/`groups.ts`/`role-assignments.ts` — swap `requireAdmin` for
   `requirePermission('org:manage-roles')`; wire in rbacVersion bumps on every mutation.
   **Not started.**
6. `heediq-api`: `errors.ts` — add `RBAC_STALE` (401). **Not started.**
7. Tests per plan (unit `rbac.ts`, integration `auth-provision`/`rbac middleware`/routes).
   **Not started.**
8. Docs: `heediq-api/README.md` §"D-102 RBAC & audit trail" update (Step 5, needs approval before
   editing). `MEMORY.md` Phase 3 status flip. **Not started.**

Not in scope for this phase (deferred to Phase 4): `GET /me`'s `effectivePermissions` field,
`heediq-web` `usePermissions`/`<Can>`, migrating `sources.ts` off legacy `custom:role`.

## Resume point
Infra changes committed locally on `feature/rbac-token-middleware-cutover` in `heediq-infra` (not
yet pushed/PR'd — waiting until `heediq-api` side is done, per "one branch = one logical change but
developer's call on when to PR"). Next: build `heediq-api/src/lib/rbac.ts`.
