# Heediq Workspace — Claude Rules (root)

This is the **single contract** for how Claude works on Heediq. It is version-controlled in
`claude-workspace` and pulled by every developer, so the team accumulates one shared memory and one
set of rules. Launch Claude from the workspace root so this file always loads.

Heediq is a B2B and B2C SaaS **contextual-memory platform** (D-143, D-144): it turns anything a
user feeds it — meetings (record/transcribe), documents, notes, files — into a structured,
AI-queryable memory (the **Context Library**). Capture → auto-classify/extract → file into a
**Context** → chat over that Context to generate any output (requirements, decisions, specs,
answers). Meeting recording & transcription is **one ingestion path**, not the whole product; the
original requirements-capture → Jira/Confluence flow is the first vertical on top of it. AWS
serverless (Lambda, EC2 GPU Spot, SQS, DynamoDB), React frontend, AWS CDK + GitHub Actions.

**This file is intentionally short and stays that way.** It is the only thing loaded into every
turn. Everything else — the full workflow steps, git conventions, UI kit rules, testing layers,
documentation structure, engineering standards, memory contract, decision-capture process,
consistency-check procedure — lives in `rules/*.md` and is read **only when the task at hand
actually touches that domain** (routing table below). Do not `@import` those files here; that
defeats the point.

---

## Repo layout

```
claude-workspace/
  CLAUDE.md                     ← you are here (thin core, always loaded)
  rules/                        ← read on demand, per the routing table below
  memory/
    business/                   ← BUSINESS memory: what we decided & why
      DECISIONS.md              ← always-loaded thin manifest: table pointing to decisions/<area>.md
      decisions/<area>.md       ← one-line-per-decision index, per area (task-scoped, not always-loaded)
      DECISIONS_FULL.md         ← full entry per decision (Decision/Why/Related code), read on demand
      DECISIONS_ARCHIVE.md      ← fully-superseded decisions, verbatim (read only on demand)
      architecture.md           ← high-level architecture overview, no per-feature implementation detail
      product.md, branding.md, BACKLOG.md
    codebase/                   ← CODEBASE memory: how the system works now
      MEMORY.md                 ← lean index: feature -> one-line summary -> README path -> decision IDs
      feature_dependency_map.md ← pure upstream/downstream/shared-surface name graph, no schemas
      STALE_ARCHIVE.md          ← trimmed content, not read unless explicitly asked for
  plans/
    wip-*.md                    ← one open WIP file per in-flight branch
```

Full documentation of *how a specific module works* lives next to the code as `README.md` — see
`rules/06-documentation.md`. Memory and `DECISIONS.md` point to those READMEs; they never duplicate
their content.

---

## Routing table — read the relevant file(s) before acting, not all of them

| When the task involves… | Read |
|---|---|
| Starting any session / resuming work | `rules/01-development-workflow.md` (Step 0), any open `plans/wip-*.md` |
| Planning a fix/feature, or writing code | `rules/01-development-workflow.md` (full Step 0–6) |
| Branching, committing, opening a PR | `rules/02-git-and-commits.md` |
| Any UI/frontend screen, component, or style | `rules/03-ui-kit.md` |
| Any async operation, spinner, progress, toast | `rules/04-loading-and-feedback.md` |
| Writing or running tests | `rules/05-testing.md` |
| Adding/updating a code README | `rules/06-documentation.md` |
| Types, security/privacy, logging, cost, a11y, perf, naming | `rules/07-engineering-standards.md` |
| Reading/writing memory or a code README | `rules/08-memory.md` |
| A decision is being locked, or you need decision history | `rules/09-decisions.md`, `memory/business/DECISIONS.md` |
| Running a cross-repo consistency check | `rules/10-consistency-check.md` |

**Only load what the task needs.** A copy-fix doesn't need `07-engineering-standards.md`; a backend
route change doesn't need `03-ui-kit.md`. When unsure whether a file is relevant, skim its one-line
purpose above before opening it in full.

---

## Session start (every session, before anything else)

1. This file is already loaded.
2. Look in `plans/` for any `wip-*.md`. If one exists, open with: *"Found open branch `<branch>` —
   continuing: `<summary>`. Still what we're doing?"*
3. Read `rules/01-development-workflow.md` Step 0 and run it (git sync, memory lookup, coherence
   check). The coherence check (`rules/08-memory.md`) is blocking — fix any mismatch before other
   work, every session, no exceptions.

---

## Four things that are always true

1. **Decisions are locked before they are built, and captured the moment they're locked**, as a full
   entry in `memory/business/DECISIONS_FULL.md` plus an index bullet in `DECISIONS.md`. Locked
   decisions are constraints in every future chat — never
   silently contradict one. If anything conflicts, flag it before responding to anything else:
   *"⚠️ This conflicts with D-NNN · [title] — supersede it or adjust the direction?"* Do not proceed
   until resolved. Full process: `rules/09-decisions.md`.

2. **Documentation lives next to the code.** Each meaningful module/folder carries a `README.md` —
   purpose, key files, data flow, contracts, gotchas. This replaces Confluence entirely.
   `rules/06-documentation.md`.

3. **The UI is built once.** Every visual element is defined once in the UI kit and reused. Every
   wait the user experiences is visible. `rules/03-ui-kit.md`, `rules/04-loading-and-feedback.md`.

4. **Memory stays coherent and minimal.** Read only what the task needs (routing table above); a
   fact lives in exactly one home (README, `DECISIONS_FULL.md`, or `architecture.md`) and is
   referenced, never copied, elsewhere. Run the coherence check every session — `rules/08-memory.md`.

---

## Decisions

Locked decisions are indexed in three tiers so a task only loads what it needs. **`memory/business/
DECISIONS.md`** is the always-loaded thin manifest — a table pointing to `memory/business/
decisions/<area>.md`, one lean one-line-per-decision index per area (architecture, infra, product,
design-brand, process, pricing-cost-policy). Open the manifest, then just the area file(s) matching
the task. Full text (decision + why + supersession pointers + one README link, no implementation
narrative) lives in `DECISIONS_FULL.md`, opened (via `grep` for the specific `D-NNN`, not a full
read) only once a decision's rationale is actually in play. Fully-superseded entries move to
`DECISIONS_ARCHIVE.md`, which is not read by default. Read the manifest before planning or writing
code that could touch a locked constraint. Never act against a locked decision without explicitly
superseding it.
