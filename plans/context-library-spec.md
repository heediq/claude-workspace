# Context Library — Design & Requirements Spec

**Status:** Requirements-definition complete (2026-07-20). No code yet. This doc consolidates the
locked design (D-124–D-139) into one readable reference to drive implementation planning. When a
module is built, its detail moves into a code README and this doc points to it.

This is a **planning/spec doc**, not a `wip-*` branch file — it stays until the feature is built out,
then is superseded by code READMEs.

---

## 1. Purpose

The Context Library turns Heediq from a meeting-transcription tool into a **general
personal/organizational memory platform**. Users feed data from many sources; Heediq
auto-organizes it into durable, structured **Contexts** (projects/activities) spanning any life
domain — work, study, personal/home — then lets the user generate any useful output from a Context
through chat backed by the Claude API.

This is the first real slice of `product.md`'s "universal contextual memory" north-star, generalized
beyond the D-069 dev-requirements use case (D-124). It builds on the generic Source/Container naming
already chosen in D-068.

**Mobile-first, web-friendly** (PWA, per `product.md`).

---

## 2. Glossary & core model

| Term | What it is | Home |
|---|---|---|
| **Domain** | Predefined system *type* carrying a behavior profile: extraction fields + starter prompts + classifier hints. `work` / `study` / `personal` / `other`. Not user-editable at MVP. | `@heediq/shared` constant (**not** a table), D-127/D-131 |
| **Context** | The user's actual project/activity; belongs to one Domain; self-nesting (project→epic→story). Accumulates Sources. (Renamed from D-068 "Container".) | `heediq-contexts` table, D-129/D-134 |
| **Source** | One ingested unit (audio, PDF, doc, image, pasted text). Files into **exactly one** Context after review. | `heediq-sources` (exists), D-128 |
| **ExtractedItem** | One individually-addressable extracted statement (a requirement, decision, action, concept…), with provenance and curation status. | new store, D-135 |
| **Decision Ledger** | Per-Context curated roll-up of key decisions & open questions; drives "precise context" + chat-time gating. **Fast-follow**, designed into the model now. | new store, D-136 |
| **Conversation** | A named chat thread scoped to a Context (ChatGPT-style); produces generated outputs. | `heediq-conversations` + `heediq-chat-messages`, D-138 |

**Domain (type, behavior-bearing) vs Context (instance, data-bearing)** is the spine: the Domain
tells the pipeline *what shape to extract* and *what outputs make sense* before it files anything;
the Context is where data accumulates.

---

## 3. Domain profiles (D-131)

Predefined enum in `@heediq/shared` with a `DOMAIN_PROFILES` config map. Adding/adjusting a profile
is a code change, not a schema migration. Fields/prompts are a starting point, refined with usage.

| Domain | `extractionFields` | `starterPrompts` |
|---|---|---|
| **work** | requirements, decisions, openQuestions, actionItems | technical requirements · test plan & acceptance criteria · stakeholder slides · risks & open questions |
| **study** | keyConcepts, definitions, questions, references, actionItems | study guide · flashcards (Q&A) · practice quiz · key-concepts summary |
| **personal** | items, amounts, dates, notes | shopping list · spending summary · upcoming dates & reminders · checklist |
| **other** | keyPoints, actionItems, notes | (generic summarize/extract — catch-all for low confidence) |

`other` is the fallback when domain-fit confidence is low (§5). Fully user-defined domains are
deferred (`BACKLOG.md`).

---

## 4. Data model

### 4.1 Context — `heediq-contexts` (new)
```
contextId (uuid, PK) · orgId · userId · domain (Domain) · name · description?
parentContextId?      // self-nesting, D-134
status ('active'|'archived') · createdAt · updatedAt
GSI by-org (PK=orgId)  // list a user's contexts / tree
```

### 4.2 Source — `heediq-sources` (exists; add fields, D-128/D-133)
```
+ contextId?                       // set on review approval
+ classification: 'pending_review' | 'approved'          // human-gate axis, separate from `status`
+ proposedClassification?          // { proposedContextId | newContextName, domain, labels[], confidence }, cleared on approval
labels[] already exists (D-068)
```
A Source files into **one** Context (D-128); `labels[]` carries cross-cutting tags.

### 4.3 ExtractedItem (new, D-135) — replaces D-132's flat `Summary.extracted`
```
itemId · sourceId · contextId? · orgId
category      // one of the filed Domain's extractionFields
text · confidence · sourceQuote?
status: 'proposed' | 'kept' | 'discarded'     // review-wizard curation
createdAt
```
`Summary` shrinks to `transcript` + a short prose gist. A Context's chat memory = all `kept` items
across the Context **and its descendants** (D-134), grouped by category, with **full Source content
still stored and available** as a detail fallback (never lossy).

### 4.4 Decision Ledger (new, D-136 — build fast-follow)
```
entryId · contextId
topic · answer|null
status: 'confirmed' | 'needs_review' | 'open'
confidence · origin: 'auto'|'user'|'chat_prompted' · sourceRefs[]
```
`needs_review` when an auto-answer's confidence < ~0.50 (distinct from §5's ~0.75 domain-fit
threshold). Chat-time gating: before generating, chat checks which ledger entries are prerequisites;
if any required ones are `open`/`needs_review`, it asks the user to fill them first.

### 4.5 Conversations (new, D-138)
```
heediq-conversations   conversationId (PK) · contextId · orgId · userId · title · createdAt · updatedAt
                       GSI by-context (PK=contextId)
heediq-chat-messages   PK=conversationId · SK=ts#messageId · role ('user'|'assistant')
                       · content · model? · createdAt
```
Multiple named conversations per Context; durable.

---

## 5. Ingest flow (auto-first, D-125/D-130/D-133)

```
1. Source ingested (record/upload audio, or upload text/PDF/image)
2. Existing pipeline: transcribe (audio) → summarize
3. Combined classify+extract — ONE Claude call in the summarization worker (D-130):
     input:  content + user's existing Contexts (name/desc/domain) + DOMAIN_PROFILES
     output: classification proposal { context|newName, domain, labels[], confidence }
             + ExtractedItems in the proposed Domain's shape
     • domain-fit confidence < ~0.75 → file to `other` Domain, flag for the user
4. Source → classification: pending_review;  proposedClassification persisted
     → WS push `classification_ready` { sourceId, proposedContext/newName, domain, labels[], confidence }
5. Interactive review wizard (D-137) — results shown step by step:
     (1) Placement       — confirm proposed Context / pick a different one (tree picker) /
                            create new (name + domain) / drop into a sub-Context
     (2) Extraction curation — each ExtractedItem one-by-one: text + proposed category + source
                            quote → keep / recategorize / edit / discard (only `kept` persists)
     (3) Ledger reconciliation — new/changed ledger entries + newly open/low-confidence ones
                            (activates with the D-136 fast-follow; core loop ships steps 1–2)
6. On approve → contextId + labels set, classification: approved
     → kept items join the Context's memory
     • cross-domain reassignment during review → cheap re-extract in the new Domain's shape;
       same-domain reassignment → no re-extract
```

User-facing stage flow (plain language): **Uploading → Transcribing (audio only) → Analyzing →
● Ready for your review → Filed in [Context]**. Every stage visible via the existing `job_status`
stream plus `classification_ready`; the review is an explicit, unmissable state — never a silent
auto-file.

---

## 6. Output generation — Context chat (D-126/D-138/D-139)

```
POST /conversations/:id/messages
  → heediq-api persists the user message, enqueues a chat job (SQS)
  → heediq-chat worker (new Lambda, 300s — mirrors summarization, D-065):
      • assemble Context memory: kept ExtractedItems (+ descendants) + Decision Ledger
        + full-source fallback (D-135/D-136)
      • build prompt with a cache_control breakpoint AFTER the stable context block
        (prompt caching — the primary cost lever; only the new user turn is uncached)
      • client.messages.stream()  → batched chat_delta WS events (~100ms) to the user
      • write final assistant message to heediq-chat-messages → chat_complete WS event
  → frontend useWsEvent('chat_delta') renders tokens live; chat_complete finalizes
```

- **Chat, not fixed templates** (D-126): predefined `starterPrompts` are shortcuts; the primary
  interaction is open chat (system prompt + Context memory + user prompt → any output).
- **Streaming rides WS**, not the REST path — API Gateway HTTP API buffers responses; the WS
  framework (`wsPush.ts` direct `PostToConnection`, D-109) is the D-111-compliant channel.
- **Model** follows the tier mapping (D-067): free→Haiku, paid→Sonnet. Revisit a stronger model for
  high-value paid outputs later (`DECISIONS.md` Open items).
- **No RAG at MVP:** a Context's content fits the context window; assemble from DynamoDB at query
  time. Revisit embeddings only when a single Context outgrows a practical token budget, or
  cross-Context semantic search is prioritized (`BACKLOG.md`).

---

## 7. WS events to add (`heediq-shared/src/ws.ts`, additive per D-109)

| Event | Payload | Purpose |
|---|---|---|
| `classification_ready` | `{ sourceId, proposedContextId \| newContextName, domain, labels[], confidence }` | Review card renders live (D-133) |
| `chat_delta` | token chunk (batched) | Live chat streaming (D-139) |
| `chat_complete` | `{ conversationId, messageId }` | Finalize the assistant turn (D-139) |

Existing `job_status` continues to drive the ingest stage indicator.

---

## 8. Scope: MVP vs fast-follow vs backlog

**MVP core loop:** ingest → combined classify+extract (`other` fallback) → interactive review wizard
(Placement + Extraction curation) → file into Context (nested) → chat over kept items, streamed,
persisted as named conversations.

**Fast-follow (model designed in now, built next):** Decision Ledger generation + fill-in UI +
chat-time gating (D-136), and the wizard's step 3 (D-137).

**Backlog (`BACKLOG.md`):** user-defined domains · multi-Context attach · cross-Context search ·
custom per-org RAG index · arbitrary connectors (email/Drive/calendar) · repo/code as a Source ·
manual context management (merge/split) · proactive assistant reasoning · additional output
types/starter-prompt library.

---

## 9. Decisions map

D-124 (generalize scope) · D-125 (auto-first classification) · D-126 (chat output) · D-127 (Domain =
behavior-bearing type) · D-128 (one Context per Source) · D-129 (Container→Context rename) · D-130
(combined classify+extract + confidence + `other`) · D-131 (Domain profiles) · D-132 (superseded by
D-135) · D-133 (`classification_ready` + review-gate state) · D-134 (nested Contexts) · D-135
(ExtractedItem) · D-136 (Decision Ledger, fast-follow) · D-137 (review wizard) · D-138 (chat
persistence) · D-139 (chat worker + WS streaming + prompt caching).

Extends D-068 (Source/Container naming). **D-140 reconciles D-069**: the Context Library *is* D-069's
MVP v1 synthesis step (chat-over-a-Context replaces the single one-shot synthesis view); D-069's
multi-source scope and critical path through source-detail are unchanged.

---

## 10. Open items (see `DECISIONS.md` Open section)

- Context chat model tier for high-value paid outputs (Opus vs Sonnet) — revisit on observed quality.
- Retrieval strategy at scale (RAG) — deferred until a Context outgrows the window or cross-Context
  search is prioritized.

---

## 11. Suggested build order (to refine in implementation planning)

**This is the MVP v1 plan for everything from source-detail onward** (D-140 reconciled D-069: the
Context Library *is* D-069's synthesis step, not a separate track). The earlier critical-path stages
— auth/onboarding → home/Listen → recordings library → source detail/summary — are unchanged from
D-069 and largely already built; source detail now surfaces curated `ExtractedItem`s. Rough sequence
for the Context Library itself:

1. **Shared contracts** (`@heediq/shared`): Domain enum + `DOMAIN_PROFILES`, Context/ExtractedItem
   schemas, Source field additions, new WS events, confidence-threshold constants.
2. **Infra**: `heediq-contexts` table (+ GSI), ExtractedItem store, Source field migration; new
   `heediq-chat` stack (SQS + Lambda + WS grant); conversations/messages tables.
3. **Ingest**: extend the summarization worker with the combined classify+extract call; emit
   `classification_ready`.
4. **API**: contexts CRUD (+ tree), review-approval endpoints (with `requirePermission` + audit +
   `<Can>`, D-107), conversations/messages endpoints, chat-job enqueue.
5. **Web**: context tree/library, source detail, the interactive review wizard, the Context chat UI
   (streaming via `useWsEvent`), all on the UI kit + motion system.
6. **Fast-follow**: Decision Ledger (generation, fill-in UI, chat gating) + wizard step 3.
