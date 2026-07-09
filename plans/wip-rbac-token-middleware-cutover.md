# WIP — D-102 Phase 3: RBAC token/middleware cutover

**Branches:** `feature/rbac-token-middleware-cutover` in both `heediq-infra` and `heediq-api` (no
`heediq-shared` change needed — the Permission catalog/schemas already exist from Phase 1).

**Design reference:** `memory/business/DECISIONS.md` D-102 (RBAC model, unchanged) · D-105
(invalidation mechanism — permissions ride the JWT, no per-request DB check, supersedes D-102's
`rbacVersion`/`RBAC_STALE`) · phase index `plans/wip-rbac-audit-trail.md` · full architecture in
`memory/business/architecture.md` §"RBAC & Audit Trail" (intentionally left stale until all 5 phases
ship).

## Plan (revised for D-105 — simplified, no per-request DB check)
1. `heediq-infra`: `custom:permissions` (String) Cognito custom attribute. **Done, being trimmed** —
   `by-group` GSI and `custom:rbacVersion` attribute (added for the now-superseded mechanism) are
   being reverted; `custom:permissions` and the existing `by-role` GSI stay.
2. `heediq-api`: new `src/lib/rbac.ts` — `ensureOrgRbacSeeded`, `ensureUserRoleAssignment`,
   `resolveEffectivePermissions`. No `bumpRbacVersion*` functions (D-105 — nothing to bump).
   **Not started.**
3. `heediq-api`: `auth-provision.ts` resolves effective permissions and stamps `custom:permissions`
   (JSON array) on every claims-issuing branch; new-org path seeds roles + admin assignment. No
   `custom:rbacVersion` claim. **Not started.**
4. `heediq-api`: `src/middleware/auth.ts` parses the `custom:permissions` claim into `AuthContext`
   alongside the existing claims (pure token read, no DB call). New `src/middleware/rbac.ts` —
   `requirePermission(permission)` checks the parsed `permissions` array from context; 403
   `FORBIDDEN` on missing permission (existing error code — no new `RBAC_STALE` code needed).
   **Not started.**
5. `heediq-api`: `roles.ts`/`groups.ts`/`role-assignments.ts` — swap `requireAdmin` for
   `requirePermission('org:manage-roles')`. No rbacVersion bump calls (nothing to invalidate
   per-request; next token refresh picks up the change naturally). **Not started.**
6. `heediq-api`: `errors.ts` — no change needed (D-105 drops `RBAC_STALE`).
7. Tests per plan (unit `rbac.ts`, integration `auth-provision`/`rbac middleware`/routes — assert
   `permissions` claim shape and `requirePermission` 403 behavior, not staleness).
   **Not started.**
8. Docs: `heediq-api/README.md` §"D-102 RBAC & audit trail" update (Step 5, needs approval before
   editing) — document D-105's mechanism, note the bounded-staleness tradeoff (permission changes
   take effect on next token refresh, not immediately). `MEMORY.md` Phase 3 status flip.
   **Not started.**

Not in scope for this phase (deferred to Phase 4): `GET /me`'s `effectivePermissions` field,
`heediq-web` `usePermissions`/`<Can>`, migrating `sources.ts` off legacy `custom:role`.

## Resume point
`heediq-infra` changes (Cognito `custom:permissions` attribute) committed locally on
`feature/rbac-token-middleware-cutover`; the `by-group` GSI and `custom:rbacVersion` attribute (added
for the now-superseded mechanism) are being reverted in the same branch before it's pushed/PR'd. Not
yet pushed — waiting until `heediq-api` side is done. Next: build `heediq-api/src/lib/rbac.ts`.
