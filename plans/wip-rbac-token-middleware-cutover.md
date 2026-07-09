# WIP — D-102 Phase 3: RBAC token/middleware cutover

**Branches:** `feature/rbac-token-middleware-cutover` in both `heediq-infra` and `heediq-api` (no
`heediq-shared` change needed — the Permission catalog/schemas already exist from Phase 1).

**Design reference:** `memory/business/DECISIONS.md` D-102 (RBAC model, unchanged) · D-105
(invalidation mechanism — permissions ride the JWT, no per-request DB check, supersedes D-102's
`rbacVersion`/`RBAC_STALE`) · phase index `plans/wip-rbac-audit-trail.md` · full architecture in
`memory/business/architecture.md` §"RBAC & Audit Trail" (intentionally left stale until all 5 phases
ship).

## Plan (revised for D-105 — simplified, no per-request DB check)
1. `heediq-infra`: `custom:permissions` (String) Cognito custom attribute. **Done** — `by-group` GSI
   and `custom:rbacVersion` attribute (added for the now-superseded mechanism) reverted; the
   `AuthProvisionFn` Lambda also wired with env vars + `grantReadWriteData` for the 3 RBAC tables
   (`ROLES_TABLE_NAME`, `GROUPS_TABLE_NAME`, `ROLE_ASSIGNMENTS_TABLE_NAME`) — the gap that would have
   crashed the Lambda at cold start. `npm run test:pre-pr` (177/177) and `cdk synth -c env=dev` both
   green; committed (`ccfd03b`), not yet pushed.
2. `heediq-api`: new `src/lib/rbac.ts` — `ensureOrgRbacSeeded`, `ensureUserRoleAssignment`,
   `resolveEffectivePermissions`. No `bumpRbacVersion*` functions (D-105 — nothing to bump).
   **Done** — unit tests in `src/__tests__/rbac.test.ts`.
3. `heediq-api`: `auth-provision.ts` resolves effective permissions and stamps `custom:permissions`
   (JSON array) on every claims-issuing branch; new-org path seeds roles + admin assignment. No
   `custom:rbacVersion` claim. **Done** — `src/__tests__/auth-provision.test.ts` rewritten to cover
   all 3 claims-issuing branches (identities-table hit, email self-heal, new-org provisioning) with
   the new `custom:permissions` claim asserted in each.
4. `heediq-api`: `src/middleware/auth.ts` parses the `custom:permissions` claim into `AuthContext`
   alongside the existing claims (pure token read, no DB call). New `src/middleware/rbac.ts` —
   `requirePermission(permission)` checks the parsed `permissions` array from context; 403
   `FORBIDDEN` on missing permission (existing error code — no new `RBAC_STALE` code needed).
   **Done** — `auth.test.ts` covers missing/malformed/unknown-permission-value rejection (401);
   `rbac-middleware.test.ts` covers `requirePermission` allow/deny (403).
5. `heediq-api`: `roles.ts`/`groups.ts`/`role-assignments.ts` — swap `requireAdmin` for
   `requirePermission('org:manage-roles')`. No rbacVersion bump calls (nothing to invalidate
   per-request; next token refresh picks up the change naturally). **Done** — route test harnesses
   (`roles.test.ts`, `groups.test.ts`, `role-assignments.test.ts`) updated to set `permissions` from
   `DEFAULT_ORG_RBAC_SEED` and assert 403 on a `member` caller.
6. `heediq-api`: `errors.ts` — no change needed (D-105 drops `RBAC_STALE`). **Done** (no-op, confirmed).
7. Tests per plan (unit `rbac.ts`, integration `auth-provision`/`rbac middleware`/routes — assert
   `permissions` claim shape and `requirePermission` 403 behavior, not staleness).
   **Done** — `pnpm run test:pre-pr` green, 151/151 unit tests, clean typecheck. No integration suite
   exists yet for this repo (README's Testing section notes this as a standing gap, not specific to
   this phase).
8. Docs: `heediq-api/README.md` §"D-102/D-105 RBAC & audit trail" update (Step 5) — documents D-105's
   mechanism, notes the bounded-staleness tradeoff (permission changes take effect on next token
   refresh, not immediately). **Done** — approved by Andrii and applied; `MEMORY.md` Phase 3 status
   flipped to reflect Phase 3 complete.

Not in scope for this phase (deferred to Phase 4): `GET /me`'s `effectivePermissions` field,
`heediq-web` `usePermissions`/`<Can>`, migrating `sources.ts` off legacy `custom:role`.

## Resume point
All 8 steps done and committed on `feature/rbac-token-middleware-cutover` in both `heediq-infra`
(`ccfd03b`) and `heediq-api` (README commit is the latest). Neither branch has been pushed to remote
yet. Next: ask Andrii whether to push + open PRs now or continue in a later session.
