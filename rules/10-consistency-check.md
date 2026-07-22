# Periodic Consistency Check

Run this check at the start of a new feature, after a multi-repo release, or when memory/docs feel stale. It catches drift between READMEs, memory, and actual code before it causes real bugs. Andrii triggers it by asking for a "consistency check" or "coherency check", or by running `/consistency-check` (project slash command, `.claude/commands/consistency-check.md`, launches Claude from the workspace root and runs this rule end to end).

This extends the per-session coherence check in `08-memory.md` (which covers only business memory files) to cover the full cross-repo surface: code, READMEs, memory indexes, and disaster recovery docs.

---

## When to run

- Before starting a multi-repo feature that touches shared contracts
- After merging a release that changed env vars, SSM paths, or SQS message schemas
- When something "felt off" in a recent session — stale gotcha, wrong path, silent failure
- On request ("run a consistency check")
- Periodically: ask Andrii at session end whether to schedule one

Claude must ask at the end of every session that involved cross-repo changes: *"Want me to run the full consistency check next session to verify everything is in sync?"*

---

## Scope — what to check

### 1. Business memory coherence (from `08-memory.md`)
Run the four-point coherence check from `rules/08-memory.md` first. It must be clean before proceeding to the broader check.

### 2. Per-repo README vs code

For every repo (`heediq-infra`, `heediq-api`, `heediq-shared`, `heediq-web`, `heediq-worker-transcription`, `heediq-worker-summarization`):

| What to verify | How |
|---|---|
| README exists at repo root | `ls README.md` |
| Key files listed in README exist at stated paths | Check each path |
| Env var names in README match actual code (`config.ts` / `config.py`) | Grep config file; compare |
| SSM/Secrets Manager paths in README match CDK stack code | Grep stack files; compare |
| SQS message schema fields in README match `@heediq/shared` `messages.ts` and Python `models.py` | Read both; compare |
| Test count / test commands in README match `package.json` / `pyproject.toml` | Grep |
| DynamoDB table names, GSIs, and key design in README match `foundation-stack.ts` | Read stack; compare |
| `heediq-api/scripts/integration/create-tables.ts` table/GSI defs match `heediq-infra/lib/foundation/tables.ts` (hand-mirrored, not imported — can silently drift, D-030) | Read both; compare |
| Account IDs, domain names, and ARNs in README match `lib/config.ts` | Compare |
| Stale "TODO" or "until PR #N merges" gotchas | Grep for "until", "file:", "to be added after", "PR #" |

### 3. Cross-repo contract consistency

Check contracts that span repos — a mismatch here causes silent runtime failures:

| Contract | Canonical source | Consumers to check |
|---|---|---|
| `SummarizationJobMessage` schema | `heediq-shared/src/messages.ts` | `heediq-worker-transcription/src/models.py`, `heediq-worker-summarization/src/handler.ts` |
| `TranscriptionJobMessage` schema | `heediq-shared/src/messages.ts` | `heediq-worker-transcription/src/models.py` (hand-maintained) |
| Lambda env var names | CDK stack `environment:{}` blocks | Lambda runtime `config.ts` / `config.py` `requireEnv()` calls |
| SSM parameter paths | CDK stack `ssm.StringParameter` writes | Consuming Lambda `config.ts` reads + README docs |
| Secrets Manager paths | CDK IAM grants (`/heediq/…/*`) + README runbook | Lambda `config.ts` `CLAUDE_SECRET_NAME` + README runbook |
| Claude model IDs | `handler.ts` `MODELS` map | `rules/07-engineering-standards.md` cost section, `DECISIONS.md` D-067 |
| Tier values (`free`/`paid`) | `heediq-shared/src/enums.ts` `TierSchema` | All message producers (API, transcription worker) and consumers (summarization worker) |
| Password policy rules | `heediq-shared/src/passwordPolicy.ts` `PASSWORD_POLICY` | `heediq-infra/lib/foundation/foundation-stack.ts` Cognito `passwordPolicy` (D-094 — deliberately not wired to `@heediq/shared`; check by hand that minLength/upper/lower/digit/symbol match) |

### 4. Memory index accuracy

- `memory/codebase/MEMORY.md`: every decision ID listed for a module actually exists in `DECISIONS.md` as Locked (not Superseded)
- `memory/codebase/MEMORY.md`: every README path pointed to actually exists on disk
- `memory/codebase/feature_dependency_map.md`: upstream/downstream entries reflect current code (no removed deps, no new deps missing)

### 5. Size & staleness control (docs/memory compression)

Memory and READMEs are a working reference, not a history log — they must stay short enough to scan
and trusted enough to act on. Check every run, not just when things "feel" cluttered:

- **`DECISIONS.md`** — any entry whose `Superseded by:` annotation shows the superseding entry now
  fully restates it (nothing substantive left active) should be archived to
  `memory/business/DECISIONS_ARCHIVE.md` per `rules/09-decisions.md` (Archiving fully-superseded
  decisions). Partially-superseded entries (annotation says "mechanism only" / "X unchanged" and that
  part isn't restated elsewhere) stay. Independent of supersession: check every remaining entry's
  `Related code` field against `rules/09-decisions.md`'s pointer-only rule — PR links, commit hashes,
  phase-by-phase merge narrative, or key/schema-level detail that now lives (or belongs) in a code
  README gets removed and replaced with a README pointer.
- **`memory/codebase/MEMORY.md`** — flag any entry that has drifted from its own contract (feature ->
  one-line summary -> README path -> decision IDs -> dependency-map entry name, nothing else,
  `rules/08-memory.md`): PR numbers, exact test counts, version numbers, or narrated build-status
  history that duplicates a code README, a `DECISIONS.md` entry, or a `plans/wip-*.md` file. Condense
  to a pointer.
- **`memory/codebase/feature_dependency_map.md`** — flag any entry that has drifted from pure
  name-only (`rules/08-memory.md`): DynamoDB key/GSI designs, SQS message schema fields, SSM param
  paths, or prose explaining *why*/*how* a dependency works. Only feature/resource/table/file *names*
  belong here; strip anything more into the owning module's README.
- **Per-repo README "Gotchas & Constraints" sections** — for each gotcha, check: is it non-obvious
  (a hidden constraint, subtle invariant, or workaround for a specific bug), or does it (a) merely
  restate something already in the same README's Data Flow/Contracts section, (b) describe a bug now
  permanently fixed with no ongoing risk, or (c) reference a merged PR / resolved "until X" caveat?
  Remove (a)–(c); keep everything genuinely non-obvious — never trim a real constraint for brevity.
- **Report a rough size delta** (lines/entries removed) alongside the usual findings table so
  Andrii can see the compression is holding, not just that it happened once.

**Never hard-delete removed content — archive it, but keep the archive out of normal context loads.**
Anything trimmed under this section (stale gotchas, condensed MEMORY.md narration, superseded
dependency-map entries) moves verbatim to `memory/codebase/STALE_ARCHIVE.md` with a one-line header
(`## <date> · <source file> · <reason removed>`) rather than being deleted outright — history stays
recoverable. `STALE_ARCHIVE.md` is deliberately **not** part of the Step 0c / session-start read set
(`01-development-workflow.md`, `08-memory.md`) and not read by this check on future runs — it exists
so nothing is silently lost, not so it gets re-loaded and burns context every session. Only open it
when Andrii explicitly asks for removed/historical content (mirrors how `DECISIONS_ARCHIVE.md` is
handled for decisions, `09-decisions.md`).

This is the same discipline as the one-off compression pass Andrii requested (2026-07-05) — it's now
a standing part of every consistency check, not a special request.

### 6. Local dev setup completeness

For each repo, verify the README covers:
- How to install dependencies (`pnpm install` / `pip install`)
- Required env vars for running locally (list them; note which require real AWS vs can be faked)
- How to run tests (`pnpm run test:pre-pr` / `pytest -q`)
- How to start the service locally if applicable
- `NODE_AUTH_TOKEN` / GitHub PAT requirement if the repo consumes `@heediq/shared`

### 7. Disaster recovery / initial setup completeness

For each repo, verify the README (or the infra README) covers:
- What must exist before the first deploy (SSM params, secrets, CDK bootstrap)
- How to trigger a fresh deploy from scratch (CI command or manual CDK command)
- How to recover if the Lambda/service needs rollback

The canonical DR doc is `heediq-infra/README.md` §"Initial Setup" and §"Setting up a new environment from scratch". Individual service READMEs should cross-reference it and add their specific prerequisites.

---

## How to run

1. Run the `08-memory.md` coherence check first. Fix any issues before continuing.
2. **Cover every real dependency edge, not an arbitrary repo-pairing.** Read `feature_dependency_map.md` first and build the actual dependency graph (upstream/downstream/shared-surface lines already state it). Spawn one parallel agent per repo that has any upstream or downstream dependency on another repo — an agent's job is to read its assigned repo *and every repo it depends on or is depended on by* (per §3's contract table plus the dependency map), not just one arbitrary partner. A repo with three dependency edges gets checked against all three, not one. Every repo in the monorepo must appear in at least one agent's scope; skipping a repo because it wasn't anyone's "pair" is the failure mode this replaces. Each agent returns a structured PASS/FAIL/MISSING table.
3. Synthesize findings. Fix critical and high-severity issues immediately (operational bugs, wrong secret paths, stale env var names). Flag medium/low for Andrii to prioritize.
4. Commit all README and memory fixes separately per repo with `docs:` or `docs(memory):` prefix.
5. After fixes are committed, push each affected repo's branch (or ask Andrii if mid-session).

### Severity tiers for findings

| Tier | Definition | Action |
|---|---|---|
| **Critical** | Would cause a production Lambda cold-start failure or wrong secret path in a runbook | Fix immediately before any other work |
| **High** | Wrong contract claim, stale env var name, wrong test count — causes confusion or silent failure | Fix in same session |
| **Medium** | Missing local dev section, missing DR section, aspirational language not flagged as future | Fix or ticket before next release |
| **Low** | Wrong version number in README prose, minor cosmetic inaccuracy | Fix opportunistically |

---

## Output format

After running, report findings as a table:

```
| # | Severity | Repo | File | Finding | Fixed? |
|---|---|---|---|---|---|
| 1 | Critical | heediq-infra | README.md:361 | Secret path says claude-api-key, code says anthropic-api-key | Yes |
| 2 | High | heediq-api | README.md:65 | Test count says 16, actual is 17 | Yes |
...
```

Then summarize: N findings, N fixed this session, N deferred. List anything deferred with a reason.
