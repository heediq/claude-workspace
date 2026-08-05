# WIP — feature/mobile-first-ui

- **Branch**: `feature/mobile-first-ui` (in `heediq-web`)
- **Goal**: Mobile-first UI/UX refinement of the heediq-web frontend — kill horizontal overflow, add a
  real mobile nav, standardise the page frame, make tables usable on phones, and codify the rules +
  responsive test gate so future work stays mobile-first. Locks D-152 (nav) and D-153 (responsive layout).

## State — implementation complete, on branch, tests green, NOT yet PR'd
Phases 0–5 done. `pnpm run test:pre-pr` green (74 files / 331 tests). `pnpm test:responsive` green
(8/8 at 320/375/768/1280). Typecheck clean.

### Done
- **Phase 0** — `h1` type token added (page titles were falling back to body size); `PageContainer` +
  `PageHeader` layout primitives; safe-area utils (`.pb-safe`/`.pb-bottom-nav`) + `viewport-fit=cover`.
- **Phase 1** — `nav-items.ts` single nav source; `BottomTabBar` (mobile) + rewritten `TopBar` (desktop);
  `AppShell` renders both with `pb-bottom-nav md:pb-0`. Logout removed from TopBar → buried in a Settings
  "Account" card (D-152). Nav clicks fire `nav_item_clicked`; logout fires `logout_clicked`.
- **Phase 2** — kit `Table` reflows to `label: value` cards below `sm` (`Table.Cell` `label` prop);
  compact `formatDateTime`/`formatDate` in `src/lib/format.ts` (+ test).
- **Phase 3** — `PageContainer`/`PageHeader` applied across all authed pages (Capture, SourcesLibrary,
  SourceDetail, ReviewWizard, RolesSettings, AuditLog, Settings). ContextLibrary intentionally keeps its
  master/detail split frame.
- **Phase 4** — Playwright installed; package-local responsive/no-overflow harness (`e2e/responsive.e2e.ts`,
  `playwright.config.ts`, `pnpm test:responsive`, projects at 320/375/768/1280). Caught + fixed a real
  Stepper overflow at 320 (labels couldn't shrink → `min-w-0` + active-only label on mobile).
- **Phase 5** — Rules codified: `rules/03-ui-kit.md` §7 rewritten (mobile-first, no-overflow invariant,
  bottom-tab nav, PageContainer/PageHeader mandate, table reflow, tap targets, safe areas) + DoD checklist;
  `rules/05-testing.md` responsive gate. Decisions D-152/D-153 locked (DECISIONS_FULL, design-brand index,
  manifest count 12→14, branding.md layout section). Gallery demos PageHeader + labeled reflow table.
  READMEs updated: `components/layout/README.md` (full rewrite), `components/ui/Table/README.md`.
  Codebase MEMORY.md updated (heediq-web decisions + E2E backlog note).

## Next
- **Decision point for the user**: open the PR now, or keep working. (Ask: "Open a PR now or keep working?")
- If PR: via `gh` only, base `develop`, NO AI co-author trailer. Body lists the two decisions + the
  responsive harness. Note reviewers should run `pnpm test:responsive` (not in the local pre-PR gate).
- **Phase 6 (separate branch/PR, not started)** — broaden the analytics EventMap for "track every
  sensible activity" → flexible funnels; lock **D-154**; curated *typed* events only, autocapture stays
  disabled, ids/enums/counts only (D-093). Update `src/lib/analytics/README.md`. Kept separate to keep
  this PR reviewable. NOTE: this branch already added the minimal `nav_item_clicked`/`logout_clicked`
  events it needed — D-154 is the broad expansion beyond those.

## Open questions / risks
- Responsive harness only covers backend-free routes (`/`, `/dev/ui`); authed pages rely on the unit
  layer for now. Full authed-route coverage would need API/auth mocking in Playwright — deferred.
- No CI wiring yet for `test:responsive` (still a manual/local gate).
