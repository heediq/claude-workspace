# Heediq Decisions Index (DECISIONS.md)

Locked decisions, split by area so a task only loads what it needs — read the manifest
below (always-loaded, this file) plus whichever `decisions/<area>.md` file(s) match the
task's area (routing in `CLAUDE.md` / `rules/08-memory.md`). Each area file is a one-line-
per-decision index, same format as before. Full text (Decision / Why / Supersedes / Related
code) lives in `DECISIONS_FULL.md`, read on demand once a specific `D-NNN` is actually in
play — grep for the ID rather than reading the whole file. Format and capture process:
`rules/09-decisions.md`.

Fully-superseded decisions (no substantive content still active) live in
`DECISIONS_ARCHIVE.md`, not here.

---

| Area file | Covers | Decisions |
|---|---|---|
| `decisions/architecture.md` | Architecture & Data Stores | 63 |
| `decisions/infra.md` | Infrastructure, Deploy & Ops | 28 |
| `decisions/product.md` | Product, Access & Billing | 21 |
| `decisions/design-brand.md` | Brand & Design | 12 |
| `decisions/process.md` | Process (this workspace) | 10 |
| `decisions/pricing-cost-policy.md` | Pricing, Cost & Policy | 7 |

---

## Open / proposed (not yet locked)
- **Exact pricing/packaging** — principle locked at D-011/D-019; revisit numbers against the post-D-059 cost basis (GPU compute: ~$0.003/free job, ~$0.010/paid job).
- **SAML/OIDC for enterprise IdPs** — explicitly deferred (D-020); revisit once an enterprise deal needs it.
- **Context chat model tier for quality outputs** — D-139 reuses D-067's free→Haiku / paid→Sonnet mapping; revisit whether high-value generated deliverables (tech specs, slides) on the paid tier warrant a stronger model (e.g. Opus) against per-generation cost, once real output quality is observed.
- **Context Library retrieval strategy at scale** — MVP assembles a Context's full accumulated content directly into the Claude chat prompt (no vector store, consistent with `product.md`'s existing RAG note). Revisit only if a single Context's content outgrows a practical context-window budget, or if cross-Context semantic search ("find where we discussed X across my whole library") becomes a prioritized feature — recommended default is to defer RAG/embeddings until one of those two triggers is real, not to build it speculatively now.
