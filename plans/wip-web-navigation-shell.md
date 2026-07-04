# WIP — Minimal app shell (logout + nav) so manual QA can proceed

**Branch:** not started yet — will be `feature/web-app-shell` off `develop` in `heediq-web`

**Goal:** Andrii is manually testing the D-078–D-087 login/sign-up/account-linking flows at
`https://dev.heediq.com/sources` and is blocked: once logged in there is no way to log out, and no
nav to reach `/settings` (proactive provider linking) — `useAuth().logout()` exists in
`AuthContext.tsx` but is not wired to any button anywhere in the app. `SourcesLibraryPage` is a
"coming soon" placeholder with no chrome at all (see `src/routes/SourcesLibraryPage.tsx`).

**State:** Not started. Confirmed via code read (this session) that:
- `AuthContext.tsx` exposes `logout()` (calls `logoutUrl()` → Hosted UI `/logout` redirect) — ready to wire up.
- No `src/components/layout/` directory exists yet (no `AppShell`/`TopBar` per `03-ui-kit.md`'s
  layered structure — `03-ui-kit.md` §3 names `PageShell`/`TopBar` as the intended layout primitives,
  neither built).
- `SourcesLibraryPage`, `SourceDetailPage` are both still placeholders.
- `SettingsPage` (provider linking, D-083) exists and works but is only reachable by typing
  `/settings` directly — no nav link to it anywhere.
- `heediq-web` PR #7 (`feature/web-scaffold` → develop, i18n aria-label fix on `ProtectedRoute`) is
  still **open**, unmerged — check whether it should land first.

**Next immediate action:** Build a minimal `TopBar`/`AppShell` layout primitive (per `03-ui-kit.md`
layering: `layouts` sit above `composed`/`primitives`) with:
1. A logout button (wire to `useAuth().logout()`) — unblocks re-testing sign-in from scratch.
2. A link to `/settings` — unblocks manual QA of proactive provider linking (D-083).
3. Mount it around the `ProtectedRoute`-gated routes (`/sources`, `/sources/:id`, `/settings`) so
   every authenticated screen has it, not just `/sources`.

Keep this small and reversible — this is scaffolding to unblock manual QA, not the full sources
library build-out. Don't scope-creep into building `SourcesLibraryPage`'s real content unless
Andrii asks for that next.

**Test scenarios once built (manual QA):**
- Role: any authenticated user. Preconditions: logged in via native sign-up, native sign-in, or SSO.
  Steps: click Logout. Expected: redirected through Hosted UI `/logout` back to `/`, `AuthProvider`
  reports `anonymous`, revisiting `/sources` redirects to `/`.
- Role: authenticated user with only a federated identity (no password set). Steps: click
  Settings link → attempt to link a second provider (D-083 proactive flow). Expected: reaches
  `SettingsPage`, `startProviderLink()` round trip works end to end.

**Open questions / risks:**
- Should the logout button live in a shared `TopBar` (kit component, reusable) or is a bare button
  on each page acceptable as a stopgap? Recommend the kit `TopBar` — matches `03-ui-kit.md`'s golden
  rule (no bespoke styling in feature code) and avoids rebuilding this per-screen later.
- Confirm whether `heediq-web` PR #7 should merge first (unrelated i18n fix, currently open)  before
  branching for the app shell, to avoid rebase noise.

---

## Standing context carried from the account-linking work (D-078–D-087, completed 2026-07-04)

All backend + frontend work for unified email-first sign-in/sign-up and cross-provider account
linking is **built and merged** across `heediq-infra`, `heediq-api`, `heediq-shared`, `heediq-web`.
Docs and memory are in sync (rule-10 consistency check run and clean as of 2026-07-04 — see
`memory/codebase/MEMORY.md`). Still genuinely open from that work: `POST /settings/link/add-provider`
backend endpoint (D-084 unblocked the dependency install, not yet built) — needed before the
*proactive* linking flow's server half works; the client-side `startProviderLink()` round trip is
ready and waiting on it.

## MVP build order reminder (D-069)
auth/onboarding → home/Listen → **sources library** → source detail/summary → multi-source upload +
container-level synthesis view. We're between "home/Listen" (done) and "sources library" (not
started, currently a placeholder) — the app-shell work above is a prerequisite unblock, not a
detour from this order.
