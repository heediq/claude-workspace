# Heediq — Product

`DECISIONS.md` (D-017–D-020, D-022, D-024–D-026, D-068, D-069, D-143, D-144) points here rather than
duplicating this detail.

## Positioning (current — D-144)
Heediq is a **contextual-memory platform**: it turns anything a user feeds it — meetings
(record/transcribe via live mic, audio upload, or pasted notes), documents, notes, files — into a
structured, AI-queryable memory (the **Context Library**). Capture → auto-classify/extract → file
into a **Context** → **chat over that Context** to generate any output (requirements, decisions,
specs, answers). Meeting recording & transcription is **one ingestion path**, not the whole product.

## Founding vertical (first use case, still shipping first)
The first vertical built on top of the platform is business-development / requirements-capture:
record or transcribe in-person meetings and discussions, then use AI to extract structured
requirements — functional specs, user stories, decisions made, open questions — optionally enriched
with existing repo/documentation context, with output feeding tools like Jira/Confluence. This
remains the MVP critical path (see Build Order); it is the *first* vertical on the memory platform,
not the platform's ceiling (D-144).

Initial target audience for that vertical: product managers, engineering leads, and BD/client-facing
roles at software companies who run frequent requirement-gathering meetings and need to turn
discussions into actionable specs without manual note-taking. Beyond it, the platform serves anyone
(B2B or B2C, D-143) accumulating a durable Context Library across work, study, and personal domains.

**Positioning is B2B *and* B2C (D-143).** The founding B2B requirements-capture use case above is one
line; Heediq also serves individuals accumulating a dynamic personal digitized memory (Context
Library). A personal user is modeled as a **single-member org** — the same tenant concept, not a
separate account type — so one model serves companies (shared Contexts around workloads/projects via
D-141 group/org visibility) and individuals. Sharing between individuals (family/friends) and between
companies both run through the same cross-org **grant** primitive (D-142, designed now / built
fast-follow).

Long-term direction: Heediq doesn't just capture requirements — it eventually helps build the
systems behind them (Heed → Define → Build; see `branding.md`).

### Long-term platform vision — universal contextual memory ("Context Library")
Generalized by D-124–D-126. The long-term platform direction below is **not** fully in MVP scope,
but a first slice of it now is — see D-069. Don't
confuse the two: D-069 (multi-source ingestion + container-level synthesis) is locked and being
built; everything else here (arbitrary connectors, full personal/professional memory, assistant
reasoning over it, custom RAG) remains north-star context, not a spec to build toward yet.

As of D-124, the Container/Source model is being requirements-designed as a generalized **Context
Library** — spanning any life domain (work/project, study, personal/home), not just dev-team
technical requirements — even though D-069's build order still ships the dev-team use case first.
Two mechanics are locked ahead of the rest of the requirements pass: **auto-first classification**
(Heediq classifies/summarizes/labels new data against existing Contexts and asks for approval; no
manual merge/split UI at MVP, D-125), and **chat-based output generation** (a Context-scoped chat
backed by the Claude API — accumulated context + system prompt + user prompt — rather than fixed
one-shot templates, D-126). Open questions (domain taxonomy, retrieval strategy at scale) and
not-yet-scoped feature ideas live in `memory/business/BACKLOG.md`.

The idea: Heediq grows from a meeting-transcription tool into a general **personal/organizational
memory platform**. Users (individuals or companies) feed it data from many sources — not just
meetings — and the system organizes it into a durable, structured knowledge base that becomes
contextual memory for their daily work and life.

- **Universal ingestion**: any data a customer puts into the system (meetings, documents, notes,
  emails, whatever a future connector supports) is a candidate input — a **Source** (D-068), not
  just audio.
- **Auto-categorization with human confirmation**: on ingest, the system proposes a Context
  match and labels, and asks a short confirmation questionnaire — "this looks related to Project
  X / Epic Y, and about auth/security — correct?" — rather than either fully automating
  classification or forcing manual filing. Keeps the human in the loop for a cheap trust-building
  check.
- **Hierarchical structure + rich labels**: a **Context** (D-068 concept, renamed from "Container"
  by D-129; project, or any ongoing user-defined activity) nests sub-Contexts (epics/stories) via
  `parentContextId`; a Source attaches to a Context *and* carries its own free-form `labels` — the
  Context answers "which activity is this part of," labels answer "what is this actually about"
  (topic, component, type) — so matching isn't limited to a single Context slot.
- **User-curated extraction**: after summarization, the user chooses which statements/decisions/
  actions/plans actually get persisted into the structured memory — extraction proposes, the user
  decides what's kept (consistent with the existing Item Detail / editable-before-export concept
  above).
- **Context-level output generation (MVP v1 — the Context Library, D-140 reconciles D-069)**: given
  several labeled Sources attached to one **Context** (renamed from Container, D-129) — e.g. meeting
  transcripts + a rules PDF + design-standard screenshots for one project — the user generates any
  output through **chat over that Context** (D-126/D-139), backed by the Claude API over curated
  `ExtractedItem`s + a Decision Ledger, instead of manually reconciling per-source summaries. This
  supersedes D-069's original "single one-shot technical-requirement synthesis view": output is now
  chat-driven and any type/any domain, not a fixed tech-requirement view. Full design:
  `plans/context-library-spec.md`.
- **End state (still north-star, not MVP)**: a comprehensive, structured memory of a user's
  ongoing activities (both professional and personal) that Heediq can reason over as an assistant
  — surfacing what's due, what was decided, and answering questions about past context, across
  arbitrary connectors (email, drive, calendar, etc.), not just uploaded files.
- **Possible monetizable extension (still north-star, not MVP)**: a per-org/per-user custom RAG
  index built from this structured memory, usable to ground responses from AI models with that
  org's/user's own context. No vector-store infra is being added now. To keep this cheap to add
  later: Sources and extracted items already carry clean provenance (which Source, which
  Context, labels, timestamps) under D-068/D-069 — that provenance is what a future embedding/
  indexing pass would need, so no extra prep work is required today beyond the D-068 naming.

D-068's generic naming (Source/Context [renamed from "Container" by D-129]/labels) is what makes the
MVP's source-matching and structured extraction the first real slice of this larger "auto-organizing
memory" capability rather than a one-off feature, without a data-model rewrite later.

Original extraction categories envisioned: **Requirements, User Stories, Decisions, Open
Questions, Action Items** — each tagged, source-linked back to the transcript (quote/timestamp),
and editable before export.

Original concept screens (early-stage reference, not all literally in MVP scope — see Build
Order below for what's actually in v1):
- **Dashboard** — session list, status (processing/ready/synced), quick "new session" button
- **New Session** — choose input method (record / upload / paste), optional project/context
- **Session Review** — transcript + extracted items, tabbed (Requirements, User Stories,
  Decisions, Open Questions, Action Items)
- **Item Detail** — each extracted item editable, with source quote/timestamp link
- **Integrations** — connect Jira/Confluence/Drive, map fields (e.g. "Requirement" → Jira
  "Story")
- **Settings** — team members, project contexts, AI extraction preferences/templates per meeting
  type

## Account & roles model
Org-first account model for every user. Personal users = a single-seat org (owner/admin), not a
separate account type — keeps the data model unified.

Roles:
- **Admin** — billing, seats, member management; sees all org content
- **Member** — sees only their own content

No per-Source sharing at launch (deferred; future option is a shareable link or explicit grant).

## Free tier & billing
Free tier is a per-org shared usage pool with a one-way usage-decay ratchet, based on cumulative
lifetime use (never resets):
- 1 use/day initially
- after 3 lifetime uses → 2 uses/week
- after 6 lifetime uses → 1 use/week

One "use" = one transcription summarized and delivered to the user. Exceeding the limit triggers
a soft upgrade prompt — never a hard block. A single paid plan exists alongside free at launch.

Billing: Stripe. Customer = the org (not the individual user); per-seat quantity-based
subscription. No card required on signup or during trial; Stripe Checkout is only triggered when
the org upgrades. Subscription state (seat count, plan status) is kept in sync via Stripe
webhooks.

Pricing principle (fair-use cap over flat per-seat, D-011) is locked; exact packaging/price is
still open and stale against the post-faster-whisper cost basis — see D-011 for the numbers and
why they need revisiting.

## Auth
AWS Cognito User Pool, with Google and Microsoft (Entra/Azure AD) as federated identity providers
from day one. On signup, email domain is checked against existing org domains — a match surfaces
a "request to join" flow that requires admin approval. Automatic domain-based addition to an org
was explicitly ruled out (security).

## Data retention & audio lifecycle
- **Free tier:** audio + transcript stored 30 days, then audio is deleted; transcript text is
  kept indefinitely (it's the actual product value, and cheap to retain).
- **Paid tier:** audio stored 90 days, then moved to S3 Glacier Deep Archive; transcript text
  kept indefinitely.
- **On cancellation:** 30-day grace period, then full org data deletion.

## Platform — PWA
Mobile-first, desktop-friendly. Installable on both mobile and desktop.
- **Offline recording:** audio captured locally, queued, uploaded on reconnect. Past transcripts
  cached for offline viewing.
- **Background recording:** true lock-screen recording is **not** reliably feasible — iOS Safari
  suspends audio capture once backgrounded. Mitigation: Screen Wake Lock API keeps the screen on
  during recording, with UI messaging explaining why.
- **Push notifications:** built at launch (not deferred) — "transcript ready" alerts via the Web
  Push API. Requires iOS 16.4+ for installed PWAs.
- **Browser/OS baseline:** iOS Safari 16.4+, Android Chrome (last 2 versions), desktop
  Chrome/Edge/Safari/Firefox (last 2 versions).
- **Breakpoints:** mobile <640px, tablet 640–1024px, desktop >1024px.
- **manifest.webmanifest:** name "heediq", background_color `#0E0D0C`, theme_color `#1A1816`,
  display: standalone.

## Home / Listen screen UX
One large "Listen" button (Shazam-style) is the primary CTA, centered. Secondary actions: upload
an audio file, upload a text file (skips transcription, goes straight to summary), view
Sources. A subtle usage/limit indicator sits in the top bar. The Sources library is a
separate nav page, not embedded in home (D-068). See `branding.md` for the Listen button's three visual
states and empty-state copy.

## Meeting bot (paid tier)
Automated meeting-join support via a third-party agent (e.g. Recall.ai) with calendar OAuth
integration, rather than building a custom bot in-house — third-party agents already solve
cross-platform call-joining reliably.

## MVP build order
Critical path (D-069 scope, D-140 reconciled the final step; sequence unchanged): **auth/onboarding →
home screen → recordings library → source detail/summary → the Context Library** (multi-source
ingest → auto-classify/extract → interactive review wizard → file into a Context → Context chat for
output generation). The final step was originally D-069's "container-level synthesis view"; D-140
replaced it with the Context Library (`plans/context-library-spec.md`) — chat over a Context rather
than a single one-shot synthesis view. Org/billing settings and calendar/meeting-bot settings are
follow-on work, after the core loop is validated.
