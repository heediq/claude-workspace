# Decisions — Process (this workspace)

Part of the decisions index (`DECISIONS.md` is the manifest). Format: `rules/09-decisions.md`.

---

- **D-012** · Workspace rules & memory repo · Process · Superseded by D-046 · → —
- **D-014** · No Jira for now · Process · Locked · → —
- **D-015** · Two-track memory + auto-decision-capture · Process · Locked · → —
- **D-016** · Documentation via code-level READMEs · Process · Locked · → —
- **D-027** · `develop` integration-branch model · Process · Locked · → `rules/02-git-and-commits.md`
- **D-046** · GitHub org rename + workspace repo rename · Process / Infra · Locked · → `claude-workspace/`
- **D-048** · Renovate for @heediq/shared dependency updates · Process · Locked · → `heediq-shared/`
- **D-049** · Hotfix flow · Process · Locked · → `rules/02-git-and-commits.md`
- **D-050** · Infra-first deployment convention · Process / Infra · Locked · → `heediq-infra/`
- **D-147** · Scripted E2E happy-path smoke per feature against dev stack · Process · Locked · → owning repo `tests/e2e/`
- **D-155** · Two-tier E2E: mocked-backend browser Playwright tier (synthetic-JWT auth seam, schema-parsed API mocks, injected fake WS, Amplitude-capture assertions; CI-on-PR) + real-stack D-147 smokes · Process · Superseded by D-156 · → `heediq-web/e2e/`
- **D-156** · Single full real-backend E2E (real Cognito/API/WS, data teardown), gated at promote-to-staging + local on-demand, never per-PR; drops D-155's mocked tier · Process · Locked · → `heediq-api/tests/e2e/`
- **D-158** · Active docs describe only what exists now (no history/obsolete/dead references); history → archives; enforced by coherence check + periodic cross-repo sync · Process · Locked · → `rules/08-memory.md`
