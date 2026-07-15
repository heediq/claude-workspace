# WIP — Minimal app shell (logout + nav) so manual QA can proceed

**Branch:** merged — PR #12 squash-merged to `develop` and deployed to `dev.heediq.com` (deploy run
28717326331, success). `feature/web-app-shell` branch deleted.

**Goal:** Andrii is manually testing the D-078–D-087 login/sign-up/account-linking flows at
`https://dev.heediq.com/sources` and is blocked: once logged in there is no way to log out, and no
nav to reach `/settings` (proactive provider linking) — `useAuth().logout()` existed in
`AuthContext.tsx` but wasn't wired to any button anywhere in the app.

**State: implementation complete, not yet manually verified against a real login, no PR yet.**
Built this session:
- `src/components/layout/TopBar.tsx` + `AppShell.tsx` (new layout primitives, `03-ui-kit.md` §3) —
  Settings link + Logout button wired to `useAuth().logout()`. See `src/components/layout/README.md`.
- Mounted `AppShell` inside `ProtectedRoute` around `/sources`, `/sources/:sourceId`, `/settings` in
  `App.tsx`. `SettingsLinkCallbackPage` deliberately left bare (transient OAuth-callback screen).
- Added `nav.settings`/`nav.logout` i18n keys (D-075/D-076).
- `SourcesLibraryPage`/`SourceDetailPage`/`SettingsPage` changed `min-h-screen` → `flex-1` (AppShell
  now supplies the full-height wrapper).
- **Found + fixed a real bug**: `Button`'s `asChild` prop was documented but never actually used
  before `TopBar` adopted it — crashed with "Slot failed to slot onto its children" any time
  `loading` was falsy (Radix `Slot` requires exactly one element child; the component was injecting
  a `null` sibling). Fixed in `Button.tsx`, regression test added, README gotcha documented.
- Typecheck clean, full suite green (87/87, incl. 2 new `TopBar`/`AppShell` test files + 1 new
  `Button` regression test). Dev server boots and `/` renders with no console errors.
- **Not yet done**: manual QA against a real Cognito login at `dev.heediq.com` (not testable from
  this local sandbox without real dev credentials) — this is now the only remaining step.

**Test scenarios (manual QA, still to run by Andrii):**
- Role: any authenticated user. Preconditions: logged in via native sign-up, native sign-in, or SSO.
  Steps: click Logout. Expected: redirected through Hosted UI `/logout` back to `/`, `AuthProvider`
  reports `anonymous`, revisiting `/sources` redirects to `/`.
- Role: authenticated user with only a federated identity (no password set). Steps: click
  Settings link → attempt to link a second provider (D-083 proactive flow). Expected: reaches
  `SettingsPage`, `startProviderLink()` round trip works end to end.
- Role: authenticated user on `/sources/:sourceId`. Expected: same TopBar chrome as `/sources`.

**Next immediate action:** Andrii tests the scenarios above live at `dev.heediq.com/sources`. Once
confirmed, this WIP file can be deleted (nothing left to resume).

---

## Standing context carried from the account-linking work (D-078–D-087, completed 2026-07-04)

All backend + frontend work for unified email-first sign-in/sign-up and cross-provider account
linking is **built and merged** across `heediq-infra`, `heediq-api`, `heediq-shared`, `heediq-web`.
Docs and memory are in sync (rule-10 consistency check run and clean as of 2026-07-04 — see
`memory/codebase/MEMORY.md`). `POST /settings/link/add-provider` backend endpoint (D-083) is now
built (`heediq-api/src/routes/settings.ts`, branch `feature/settings-link-add-provider`, pre-PR gate
green) — the *proactive* linking flow's server half is complete. What's still open: the manual QA
round trip against a real Cognito login (test scenario 2 below) has not yet been executed by Andrii.

## MVP build order reminder (D-069)
auth/onboarding → home/Listen → **sources library** → source detail/summary → multi-source upload +
container-level synthesis view. We're between "home/Listen" (done) and "sources library" (not
started, currently a placeholder) — the app-shell work above is a prerequisite unblock, not a
detour from this order.
