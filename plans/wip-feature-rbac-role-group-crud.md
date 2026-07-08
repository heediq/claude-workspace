# WIP — feature/rbac-role-group-crud (D-102 Phase 2)

**Branch**: `feature/rbac-role-group-crud` — created in **three repos**: `heediq-shared`,
`heediq-api`, `heediq-infra` (all off `develop`).

**Goal**: Role/Group/Role-Assignment CRUD routes in `heediq-api` + the audit write path
(`AuditPayloadMap`-driven, per D-102), wired to the Phase 1 tables/schemas. Standing index:
`plans/wip-rbac-audit-trail.md`.

**State**: Implementation complete across all three repos, PRs open, awaiting merge/review:
- `heediq-shared`: `CreateRoleRequestSchema`/`UpdateRoleRequestSchema`/`CreateGroupRequestSchema`/
  `UpdateGroupRequestSchema`/`CreateRoleAssignmentRequestSchema` + `buildAuditLogEntry()`. Published
  as `0.10.0`. [PR #26](https://github.com/heediq/heediq-shared/pull/26).
- `heediq-infra`: `ApiStack` granted read-write on `heediq-roles`/`heediq-groups`/
  `heediq-role-assignments`, write-only on `heediq-audit-log`; 4 new env vars.
  [PR #49](https://github.com/heediq/heediq-infra/pull/49).
- `heediq-api`: `routes/roles.ts`, `routes/groups.ts`, `routes/role-assignments.ts`, `lib/audit.ts`
  (`writeAuditEvent()`), mounted in `app.ts`. All writes gated by interim `requireAdmin()` (checks
  legacy `role === 'admin'`, D-017) — full `Permission`-based enforcement is Phase 3.
  [PR #24](https://github.com/heediq/heediq-api/pull/24).

Gates green in all three repos: typecheck clean, full test suites passing (heediq-shared 128/128,
heediq-infra 176/176, heediq-api 138/138 — verified against the real published `@heediq/shared@0.10.0`,
no local symlink). READMEs updated in all three repos (Key Files, Contracts/endpoints, Dependencies,
Testing, Gotchas).

**Next**: Once all 3 PRs are reviewed and merged to `develop`, update
`plans/wip-rbac-audit-trail.md`'s Phase 2 row to `Done` (with merge commits) and delete this file.

**Resolved implementation notes** (kept for the PR review / next-session context):
- Interim authz: gated behind `role === 'admin'`, to be replaced by
  `requirePermission('org:manage-roles')` in Phase 3 — approved as a temporary measure.
- `writeAuditEvent` split: `@heediq/shared` owns the pure `buildAuditLogEntry()` (constructs +
  validates via `AuditLogEntrySchema`, zero AWS SDK deps); `heediq-api` owns the actual `PutCommand`
  (`lib/audit.ts`'s `writeAuditEvent()`) — consistent with every other DynamoDB access living in
  `heediq-api`.
- Hono routing gotcha: a sub-router mounted under a parent path segment (e.g. `:userId`) can't see
  that param in its own type inference — `role-assignments.ts` declares its full path
  (`/:userId/role-assignments...`) and is mounted at `/users` in `app.ts`, not at
  `/users/:userId/role-assignments`.
