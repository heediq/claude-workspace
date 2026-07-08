# WIP — feature/rbac-role-group-crud (D-102 Phase 2)

**Branch**: `feature/rbac-role-group-crud` — created in **three repos**: `heediq-shared`,
`heediq-api`, `heediq-infra` (all off `develop`, all synced at branch time).

**Goal**: Role/Group/Role-Assignment CRUD routes in `heediq-api` + the audit write path
(`AuditPayloadMap`-driven, per D-102), wired to the Phase 1 tables/schemas. Standing index:
`plans/wip-rbac-audit-trail.md`.

**State**: Step 0 done (resume check, git sync, memory/decisions read, coherence check clean).
Step 1/2 (questions + plan) in progress — plan not yet approved, no code written yet.

**Next**: Present the Step 2 plan (routes, audit-write-path split between `heediq-shared` and
`heediq-api`, interim permission gating since Phase 3's `requirePermission`/`rbacVersion` doesn't
exist yet) for approval before implementation.

**Open questions / risks**:
- Interim authz: Phase 3 (token/middleware cutover) hasn't shipped, so the JWT still only carries
  the fixed `custom:role` claim (admin/member, D-017 legacy). Plan proposes gating all new
  roles/groups/assignments routes behind `role === 'admin'` as a temporary check, replaced by
  `requirePermission('org:manage-roles')` in Phase 3 — flagging for explicit approval since it's an
  implementation judgment call, not a locked decision.
- `writeAuditEvent` split: D-102/architecture.md says the helper lives in `@heediq/shared`, but
  shared has zero AWS SDK dependencies today (schema/pure-function package only). Proposing
  `@heediq/shared` owns a pure `buildAuditLogEntry()` (constructs + validates the entry via
  `AuditLogEntrySchema`, keeps the PII-prevention typing), while `heediq-api` owns the actual
  `PutCommand` (`writeAuditEvent()` wrapping it) — consistent with every other DynamoDB access
  living in `heediq-api`. Flagging for approval rather than adding `@aws-sdk/*` as a new shared dep.
