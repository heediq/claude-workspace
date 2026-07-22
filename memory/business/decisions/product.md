# Decisions — Product, Access & Billing

Part of the decisions index (`DECISIONS.md` is the manifest). Format: `rules/09-decisions.md`.

---

- **D-017** · Account & roles model · Product · Superseded by D-102 · → `memory/business/product.md`
- **D-024** · Platform — mobile-first PWA · Product · Locked · → `memory/business/product.md`
- **D-025** · Paid-tier meeting bot · Product · Locked · → `memory/business/product.md`
- **D-060** · Model access control at API layer, not infra routing · Product / Architecture · Locked · → `heediq-api/`
- **D-079** · Account linking is available both reactively (login-time) and proactively (Settings) · Product · Locked · → `heediq-web/src/routes/SettingsPage.tsx`
- **D-081** · No separate marketing/landing page — "/" is always the sign-in/sign-up screen · Product · Locked · → `heediq-web/src/App.tsx`
- **D-111** · Every feature with async backend work must use the WS framework for responsiveness · Product · Locked · → `heediq-web/src/lib/ws/README.md`
- **D-124** · Context Library generalizes north-star scope beyond dev-work to any life domain · Product · Locked · → `memory/business/product.md`
- **D-125** · Context Library — auto-first classification, no manual merge/split at MVP · Product · Locked · → —
- **D-126** · Context Library — output generation via chat, not fixed one-shot templates · Product · Locked · → —
- **D-127** · Context Library — Domain is a predefined, behavior-bearing type · Product / Architecture · Locked · → `heediq-shared/src/`
- **D-128** · Context Library — one Context per Source at MVP · Product / Architecture · Locked · → `heediq-shared/src/domain.ts`
- **D-131** · Context Library — Domain profile set: work / study / personal / other · Product / Architecture · Locked · → `heediq-shared/src/`
- **D-134** · Context Library — nested Contexts (epic/story) are in MVP scope · Product · Locked · → `heediq-shared/src/`
- **D-136** · Context Library — Context Decision Ledger (design now, build fast-follow) · Product / Architecture · Locked · → `heediq-shared/src/`
- **D-137** · Context Library — interactive 3-step review wizard · Product / Design · Locked · → `heediq-web/src/features/`
- **D-140** · MVP v1 synthesis step reconciled to the Context Library · Product · Locked · → `plans/context-library-spec.md`
- **D-141** · Context Library — Context visibility model: personal / group / org, permission-gated · Product / Architecture · Locked · → `heediq-infra/lib/foundation/README.md`
- **D-143** · Heediq serves B2B and B2C; org is the universal tenant boundary · Product · Locked · → `memory/business/product.md`
- **D-144** · Primary positioning is a contextual-memory platform; meetings are one ingestion path · Product · Locked · → `memory/business/product.md`
