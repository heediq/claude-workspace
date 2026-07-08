# WIP tracker — RBAC & audit trail build-out (D-102)

**Not a single branch** — this tracks a 5-phase initiative across multiple branches/sessions. Each
phase gets its own `feature/<phase-desc>` branch and, while in flight, its own
`plans/wip-<branch>.md` per the normal convention (`plans/README.md`). This file is the standing
index across phases so the sequence and status survive between sessions — update it whenever a
phase starts, pauses, or merges. Delete only when all 5 phases are merged and D-102's `Related
code:` field has been updated to point at the built code READMEs.

**Design reference:** `memory/business/DECISIONS.md` D-102 · full architecture in
`memory/business/architecture.md` §"RBAC & Audit Trail".

## Phase status

| # | Phase | Scope | Status | Branch / WIP file |
|---|---|---|---|---|
| 1 | Shared catalog + tables | `heediq-shared/src/permissions.ts`, `src/audit.ts`; `heediq-infra` FoundationStack tables (`heediq-roles`, `heediq-groups`, `heediq-role-assignments`, `heediq-audit-log`) + `defaultRoleId` on `heediq-orgs` | **Not started** | — |
| 2 | Role/group CRUD + audit write path | New `heediq-api` routes for roles/groups/assignments; `writeAuditEvent` helper; per-resource-type payload resolution | Not started | — |
| 3 | Token/middleware + provisioning cutover | `auth-provision.ts` seeds `DEFAULT_ORG_RBAC_SEED` + stamps `custom:permissions`/`custom:rbacVersion`; `requirePermission` middleware; `RBAC_STALE` 401 | Not started | — |
| 4 | Frontend RBAC UI | `heediq-web` role/group management screens; `usePermissions`/`<Can>` wrappers wired into existing screens | Not started | — |
| 5 | Audit log viewer | `GET /org/audit-log` (cursor-paginated, filterable); `/org/audit-log` route in `heediq-web` | Not started | — |

## Rules
- Phases build in order — each depends on the previous (tables before CRUD, CRUD before
  token/middleware cutover, etc.). Don't start phase N+1 before phase N is merged to `develop`.
- On starting a phase: create its `feature/<desc>` branch + `plans/wip-<branch>.md`, then update
  this table's Status/Branch columns.
- On merging a phase: mark Status `Done`, note the merge commit/PR, and delete that phase's
  per-branch WIP file (normal convention). Leave this row `Done` for history until all 5 are done.
- On pausing mid-phase: the per-branch WIP file carries the detailed resume state (per
  `01-development-workflow.md` Step 0a); this file only needs its Status cell updated (e.g.
  "In progress — see wip-<branch>.md").
