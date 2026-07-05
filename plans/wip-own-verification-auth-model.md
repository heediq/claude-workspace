# WIP — Own-verification auth model (D-089/D-090/D-091)

**Branches:** `feature/own-verification-auth-model` in both `heediq-api` and `heediq-web`.
**State: implementation complete, fully tested, documented. Zero commits made yet in either repo.**

## Why
QA found: log in with Google, log out, try email/password sign-in with the same address → got a
plain "create password" form with no linking/verification. Root cause: Google/Microsoft
`attributeMapping` never mapped `email_verified`, so `auth-provision.ts`'s D-080 gate silently
skipped org provisioning on every federated login. Rather than patch the mapping, three decisions
replaced the model — see `memory/business/DECISIONS.md` D-089, D-090, D-091 for full text.

## What's built (this session + prior session, verified working)
- **heediq-api** (63/63 tests green, typecheck clean):
  - `auth-provision.ts` — drops the `email_verified` gate entirely (D-090); resolves the existing
    user row **by email first, falling back to `sub`** (a post-linking re-login presents the
    destination/native user's `sub`, not the original federated one).
  - `routes/auth.ts` — `request-otp`/`confirm` generalized beyond `/auth/link/*` to also serve
    native signup and Settings proactive-linking (D-089).
  - `routes/auth-methods.ts` — new `GET /api/v1/auth/methods` (D-091), scoped to caller's `userId`.
- **heediq-web** (95/95 tests green, 23 test files, typecheck clean):
  - `src/features/auth/VerifyAndSetPasswordForm.tsx` — new shared two-step component (first use of
    the `src/features/` layer in this codebase). See `src/features/auth/README.md`.
  - `HomePage.tsx` — collapsed signup + reactive-linking into one `verify` step using the shared
    component; no more separate sign-up form.
  - `SettingsPage.tsx` — renders D-091's active-methods list read-only + inline "Set a password"
    using the shared component; first feature-level use of TanStack Query outside `App.tsx`.
  - `cognito-idp.ts` — no longer exports `signUp`/`confirmSignUp`.
- **Documentation (Step 5, user-approved via AskUserQuestion "Yes, proceed with all four")**:
  `heediq-api/README.md`, `heediq-web/README.md`, `heediq-web/src/lib/auth/README.md` all updated;
  `heediq-web/src/features/auth/README.md` newly created.
- **Memory (Step 6)**: `DECISIONS.md`, `MEMORY.md`, `feature_dependency_map.md` all updated and
  committed (`ae7fb0b`) to reflect D-089/D-090/D-091 as built, not just locked.

## Known workaround — must resolve before shipping
`@heediq/shared@0.3.0` on the registry does **not** contain `AuthMethodSchema`/
`ListAuthMethodsResponseSchema` (added to `heediq-shared/src` but never published). Both repos are
currently verified against a **manual dev-only dist copy** (`heediq-shared`'s `dist/*.js`/`*.d.ts`
hand-copied into each repo's local pnpm store). This is not a real fix — a version bump + publish
of `heediq-shared` is required before either branch can actually ship. Raise this explicitly at PR
time, not before.

## Not yet done
- **No git commits in either repo.** Everything above is uncommitted working-tree state. Suggested
  commit boundaries next session: (a) heediq-api — `auth-provision.ts` D-090 fix, (b) heediq-api —
  `GET /auth/methods` D-091 route, (c) heediq-web — collapse signup/linking into shared
  verify-and-set-password flow (D-089), (d) heediq-web — SettingsPage active-methods list (D-091),
  (e) docs commit per repo. Conventional Commits, no AI co-author trailer (workspace rule).
- **heediq-shared version bump + publish** (see above) — flag at PR time.
- **End-of-session question still open**: ask Andrii "Open a PR now or keep working on this branch
  in another session?" once commits are made — don't open a PR unprompted.

## Next immediate action
Make the git commits above in `heediq-api` and `heediq-web`, then ask about opening a PR.
