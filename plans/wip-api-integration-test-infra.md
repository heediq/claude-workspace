# WIP — heediq-api integration test layer + centralized seeding

**Branch:** `feature/api-integration-test-infra` (not yet created — plan approved in discussion,
no code written yet)

**Goal:** Build the integration test layer that `05-testing.md` locks (D-030: Vitest + DynamoDB
Local/LocalStack) but that doesn't exist yet in `heediq-api` — no `tests/integration/`, no
docker-compose/LocalStack config, nothing. Net-new infra, not an extension. Triggered by manually
verifying a fresh signup (email/password-first, Google-linked-after) against real AWS dev
DynamoDB/Cognito and wanting the same checks automated + reusable for future stress-test data
generation.

## State
Plan drafted and walked through with Andrii; not yet approved to start building. Open question below
is blocking Step 1.

## Plan (from the last session)

1. **DynamoDB Local via docker-compose** (`heediq-api/docker-compose.integration.yml`,
   `amazon/dynamodb-local` image) — real DB behavior (conditional writes, GSI query semantics)
   without touching AWS.
2. **Table bootstrap script** (`scripts/integration/create-tables.ts`) mirroring every
   table/GSI definition from `heediq-infra/lib/foundation/tables.ts`. Risk: this becomes a second
   source of truth that can silently drift from `tables.ts` — flag in both READMEs, cross-reference,
   and add a line item to `10-consistency-check.md`'s per-repo table once built.
3. **Centralized seeding module** (`tests/integration/seed.ts`) — composable builders (`seedOrg()`,
   `seedUser()`, `seedRoles()`, `seedRoleAssignment()`, `seedFullOrg()` convenience wrapper). Reused
   later for stress-test (k6) data generation — write the seeding logic once, import it from both
   places.
4. **Auth-provisioning tests exercise the real handler** (`src/handlers/auth-provision.ts`) directly
   against DynamoDB Local via synthetic Cognito `PreTokenGeneration` events (driving actual Cognito/
   Google OAuth in CI isn't practical). Covers: brand-new org provisioning, existing-user resolution
   via identities table, email self-heal path, both signup orderings (native-first-then-Google-
   linked, Google-first-then-native-linked).
5. **Route-level integration tests** (`/me`, `/org/audit-log`, role/group CRUD) run the real Hono app
   in-process against DynamoDB Local instead of mocked `dynamo.send()` — catches wrong-key-shape bugs
   that a mock can't (this exact class of bug came up this session: a manual verification query used
   the wrong partition-key shape for `heediq-role-assignments` and looked like a false RBAC bug until
   re-checked against the real key format in `rbac.ts`).

### Tests to add
- `tests/integration/auth-provision.test.ts` — new-org provisioning (all 6 tables in one pass),
  existing-user token refresh (`resolveEffectivePermissions` against real seeded data), IdP-first vs
  native-first orderings, email self-heal fallback.
- `tests/integration/rbac.test.ts` — `resolveEffectivePermissions` including group-mediated
  permissions (untested today — no group has existed in any account checked so far).
- `tests/integration/audit-log.test.ts` — `GET /org/audit-log` pagination against a real
  `LastEvaluatedKey`, not a hand-rolled mock.
- Existing mocked-`dynamo.send` unit suites stay as-is (two-layer model, `05-testing.md`) — this adds
  the missing layer, doesn't replace the existing one.

**Logging:** none new — test-only code, not exercised in prod.
**Rollback:** delete `docker-compose.integration.yml`, `scripts/integration/`, `tests/integration/`;
no production code touched.
**Risk & Regression:** Low — additive only. Ongoing cost is the schema-mirroring drift risk noted in
item 2.

## Open question (blocking)
Andrii hasn't yet said whether to scope this to DynamoDB Local only, or use full LocalStack so SQS/S3
are covered by the same harness in the same pass (relevant since transcription job flow uses SQS/S3
too, and the user separately wants stress-testing reuse). Resolve this before Step 1.

## Next
Ask/confirm DynamoDB-Local-only vs LocalStack scope, then start Step 1 (docker-compose + table
bootstrap script) on the new branch.
