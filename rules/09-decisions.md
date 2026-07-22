# Decision Capture & Business Memory

Heediq is a brand-new product: decisions about scope, design, architecture, cost, pricing, and brand
are made constantly in conversation. This module defines how those decisions are **captured
automatically**, kept as **business memory**, and applied as **constraints** in every future chat.

## Two memory tracks (keep them separate, both live in `memory/`)
- **Business memory** (`memory/business/`) — *what we decided and why*. Product, design, architecture,
  infra, cost, pricing, branding, scope, positioning. `memory/business/DECISIONS.md` is the
  always-loaded one-line-per-decision index; `memory/business/DECISIONS_FULL.md` holds the full entry
  (Decision/Why/Supersedes/Related code) for each, read on demand.
- **Codebase memory** (`memory/codebase/` + code READMEs) — *how the system works now*. Index, the
  feature dependency map, and per-module READMEs.

A decision is recorded **once** in business memory; code READMEs reference it rather than copying it.

## What counts as a decision (capture these)
Anything that constrains future work or that we'd later want the "why" for:
- Product scope / which features are in or out, and build order
- UX & design choices (layouts, flows, component behavior, design tokens)
- Architecture & infrastructure (services, data model at the product level, vendors/tools)
- Cost & performance tradeoffs (model tiers, optimizations accepted/rejected)
- Pricing & packaging
- Branding, naming, positioning, copy direction
- Policy (privacy, retention, security posture)

Not decisions: routine implementation details that belong in a code README, and anything still being
brainstormed.

## Automatic capture — the core behavior
**When Andrii locks a decision, record it immediately and unprompted**, then give a one-line
confirmation. Do not wait for the end of the task, and do not ask "should I save this?" once it's
clearly locked.

1. **Detect the lock.** Lock signals include explicit phrasing ("this is locked", "decided", "let's
   go with X", "yes, do that") or a clear confirmation of a proposed option. Andrii's style is to lock
   explicitly and sequentially.
2. **If it's genuinely ambiguous** whether something is a firm decision or still open discussion, ask
   one short question: *"Lock this as a decision?"* — don't record open brainstorming as locked.
3. **Before writing, verify against existing decisions** (see `rules/08-memory.md` — Verify before
   every write). Specifically:
   - Does an existing entry already cover this? If yes, update it rather than adding a duplicate.
   - Does this conflict with an existing locked decision? If yes, flag it before writing:
     *"This conflicts with D-NNN (title) — supersede it, or keep both?"*
   - Is the scope or wording unclear? Ask one short question before writing.
4. **Write the full entry to `memory/business/DECISIONS_FULL.md`** in the entry format below, and add
   its one-line bullet to the index in `memory/business/DECISIONS.md`.
5. **Confirm in one line**, e.g. *"Locked → recorded as D-014 in DECISIONS.md / DECISIONS_FULL.md."*
6. **Claude never self-locks.** Claude proposes and records; only Andrii locks. If Claude recommends
   something, it stays a proposal until Andrii confirms.

## Apply decisions as constraints (every chat)
- Read `DECISIONS.md` at task start (Step 0c). Treat locked decisions as binding context.
- **Never silently contradict a locked decision.** This applies to both discussion and code.

## Conflict detection — blocking, real-time

If **anything being discussed, planned, or requested** conflicts with a locked decision, stop
immediately and flag it **before responding to the substance**:

> *"⚠️ This conflicts with **D-NNN · [title]**: [one sentence stating what is locked]. Supersede
> D-NNN, or adjust the current direction?"*

Do not proceed, do not offer an implementation, do not work around it silently. Surface the conflict
first — every time, even if it seems obvious that Andrii already knows.

A conflict is resolved only when Andrii explicitly supersedes the old decision (new D-NNN entry) or
confirms the discussion is actually consistent with it. "Proceed anyway" is not a resolution.

**What counts as a conflict:**
- A request or proposal that directly contradicts the text of a locked decision
- A design or implementation that would violate a locked constraint (stack, naming, cost, security)
- A new decision being discussed that overlaps a locked one without explicitly superseding it

## Superseding, not duplicating
Decisions evolve. When a new decision changes an old one:
- Set the old entry's **Status: Superseded by D-NNN** (keep it — history matters for the "why").
- Add the new entry with **Supersedes: D-MMM**.
Never delete a decision or silently edit its meaning; supersede it.

## Archiving fully-superseded decisions
`DECISIONS_FULL.md` (and its one-line bullet in the `DECISIONS.md` index) stay lean by moving
decisions to `memory/business/DECISIONS_ARCHIVE.md` once they carry no substantive active content —
this is not deletion, the entry is preserved verbatim with its full rationale, just out of the main
reading path.

- **Archive** a decision when its superseding entry's text already restates whatever part of it is
  still true (i.e. the old entry adds nothing beyond history).
- **Keep** a decision whose superseding annotation says only part changed (e.g. "mechanism only",
  "compute only", "X unchanged") and that unchanged part isn't fully restated in the superseding
  entry — it's still load-bearing, not just historical.
- When archiving, move the full entry as-is (same fields, same wording) from `DECISIONS_FULL.md`
  into `DECISIONS_ARCHIVE.md`, and remove its bullet from the `DECISIONS.md` index; leave its
  `Superseded by:` reference intact so a reader following an ID from the index into the archive can
  still see why.
- This decision applies going forward as part of the periodic consistency check
  (`rules/10-consistency-check.md`) — don't wait for memory to feel cluttered before archiving.

## Status lifecycle
`Proposed` (optional, while under discussion) → `Locked` → `Superseded` / `Reversed`.

## Entry format (full text in `DECISIONS_FULL.md`, index bullet in `DECISIONS.md`)
Full entry, in `DECISIONS_FULL.md`:
```
### D-014 · <short title> (YYYY-MM-DD) — Locked
**Area:** Product | Design | Architecture | Infra | Cost | Pricing | Brand | Policy
**Decision:** One or two sentences stating exactly what was decided.
**Why:** The rationale / what it was chosen over.
**Supersedes:** D-MMM (or —)         **Superseded by:** D-NNN (or —)
**Related code:** path/to/module/README.md (once implemented, or —)
```

Matching index bullet, in `DECISIONS.md`, grouped under the same `## ` area section:
```
- **D-014** · <short title> · <Area> · <Locked | Superseded by D-NNN> · → path/to/module/README.md (or —)
```

Keep the full entry lean: the decision + its rationale (3–5 sentences), not an essay. Detail about
*how it's built* belongs in the code README the entry points to — never in `DECISIONS_FULL.md`
itself. The index bullet is one line, no rationale — just enough to know the decision exists and
where to look.

**`Related code` is a pointer, never a build log.** It names the README(s) (and, only if no README
exists yet, the file/path) that carry the implementation. It never contains PR links, commit hashes,
phase-by-phase merge narrative ("Phase 1 done... Phase 2 merged via..."), or key/schema-level detail
(DynamoDB keys, GSI design, message shapes) — that content lives in the module's README
(`rules/06-documentation.md`) and, once it does, gets removed from here, not duplicated. Git history
already tells you what merged when; `DECISIONS.md` only needs to tell you *what* was decided and
*why*.

## End-of-task pass (ties into Step 6)
Confirm every decision locked during the task has a full entry in `DECISIONS_FULL.md` and a matching
bullet in the `DECISIONS.md` index, any superseded entries are marked in both, and
`memory/codebase/MEMORY.md` carries a pointer only for new *in-progress* items (never full decision
text).
