# Product Feature Backlog

Feature ideas and postponed scope that aren't locked decisions and aren't yet a spec to build
toward — the "we'll come back to this" list. Distinct from:
- **`DECISIONS.md`'s "Open / proposed"** section — a specific open question hanging off an
  already-locked decision.
- **`memory/codebase/MEMORY.md`'s "Backlog"** section — engineering/ops debt (rate limiting,
  secrets rotation, bundle-size budgets), not product features.

When an item here gets scoped and locked, move it to `DECISIONS.md` (or supersede/remove it from
here) rather than keeping it in both places.

## Context Library (D-124–D-126)
- **Additional output types / starter-prompt library.** D-126 locks chat as the generation
  mechanism; the actual set of predefined starter prompts (test plans, acceptance criteria,
  stakeholder slides, meeting-prep briefs, etc.) isn't scoped yet.
- **Cross-Context search.** "Find where we discussed X across my whole library" — needs semantic
  search/retrieval across many Contexts, not just chat within one open Context. See DECISIONS.md's
  open item on retrieval strategy — deferred until content volume or a concrete ask makes it real.
- **Custom per-org/per-user RAG index (monetizable extension).** Already noted in `product.md`'s
  north-star as a possible paid extension once structured memory + provenance exists. No
  vector-store infra planned now.
- **Arbitrary connectors beyond upload** (email, Drive, calendar, etc.) as additional Source
  types feeding a Context. `product.md` north-star; D-068's generic Source naming already
  anticipates this.
- **Repo/code access as a Context source.** Raised 2026-07-20 — letting a Context see a project's
  actual repo/code (not just meeting/doc sources) for tech-requirement generation. Explicitly
  post-MVP.
- **User-defined domains.** D-127 locked a predefined behavior-bearing Domain enum
  (work/study/personal, extensible by code). Fully user-defined/custom domains — where a user
  authors their own extraction profile + starter prompts — are deferred here.
- **Multi-Context attach for a Source.** D-128 locked one Context per Source at MVP. Letting a
  Source belong to several Contexts (D-068's original "one or more") is deferred — needs multi-select
  review UI and shared-source dedupe in context-memory assembly.
- **Manual context management** (rename/merge/split, override auto-classification beyond the
  approval step). D-125 chose auto-first + approval-only for MVP; revisit if auto-classification
  accuracy in practice turns out to need it.
- **Proactive assistant reasoning.** `product.md`'s north-star end-state — Heediq surfacing what's
  due / what was decided unprompted, not just answering in reactive chat. Still north-star, no
  scoping done.
