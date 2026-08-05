# UI Kit — Style Once, Reuse Everywhere

The goal: a single, comprehensive library of styled, reusable building blocks (buttons, inputs,
spinners, progress bars, cards, layouts, …) so any screen is assembled by **combining existing kit
components**, never by re-styling elements inline. One definition per element → consistent,
professional, fast to build. This pairs with `04-loading-and-feedback.md` (every wait visible) and
`07-engineering-standards.md` (a11y, perf).

Design register is already locked: restrained, premium, Linear / Vercel / Raycast alignment. Charcoal
+ amber tokens; Inter / Geist for UI; JetBrains Mono for transcripts. The kit *enforces* that register
so individual screens can't drift.

---

## 1. The golden rule
**No bespoke styling in feature code.** If a screen needs a visual element, it uses a kit component.
If the kit doesn't have it, you either (a) add a **variant** to an existing component, or (b) add a
**new component** to the kit — then use it. A raw `<button className="bg-amber-500 …">` in a feature
file is a bug. The only styling allowed in feature code is **layout composition** (arranging kit
components via the layout primitives), not visual styling of primitives.

## 1a. No hardcoded user-facing strings — ever
Every piece of user-facing text — labels, copy, empty/error states, toasts, `aria-label`s, alt text,
placeholder text — is a translation key resolved through `t()`, never a literal string in JSX/TS.
This applies to `heediq-web` in full, per D-075 (100% i18n coverage, including error messages) and
D-076 (`react-i18next`, single bundled `src/i18n/locales/<lng>/translation.json` — bundled at build
time, not fetched from `public/`, so `t()` works synchronously with no loading gap). A literal string
anywhere a user can see it (including screen-reader-only text) is a bug, exactly like a raw hex color
is a bug under the golden rule above. The `/dev/ui` component gallery is the one exception (dev-only,
build-guarded out of prod) where demo copy may be literal.

## 1b. Any UI work uses the kit + the motion system — no exceptions
Before writing or editing any screen, component, or transition, use what already exists:
**kit components** (`03-ui-kit.md`, this file) for every visual element, and the **shared motion
system** (`heediq-web/src/lib/motion.ts`, D-117) for every mount/unmount, appear/disappear, or
page-to-page transition. Never hand-roll a bespoke `motion.div` with inline `variants`/`transition`
props in feature code — that is the motion-system equivalent of a raw `className="bg-amber-500 …"`
button under the golden rule (§1), and the same fix applies: reuse an existing motion variant, or add
a new one to `motion.ts` and use it. This check runs at the start of any UI task, before planning —
confirm both the kit component and the motion variant needed exist (or must be added) as part of Step
2's UI-conformance section (`01-development-workflow.md`).

## 2. Design tokens are the single source of truth
All visual values live in one place (Tailwind theme config + CSS variables), never hardcoded in
components:
- **Color** — charcoal/amber semantic tokens: `--bg`, `--surface`, `--border`, `--text`,
  `--text-muted`, `--accent` (amber), `--accent-fg`, plus state colors `--success`, `--warning`,
  `--danger`, `--info`. Components reference *semantic* tokens, never raw hex or raw palette steps.
- **Typography** — font families (Inter/Geist UI, JetBrains Mono transcripts), a type scale
  (display/title/body/caption/mono), weights, line-heights. No ad-hoc `text-[13px]`.
- **Spacing** — one spacing scale (4px base). No magic-number margins.
- **Radii, shadows, borders, z-index, motion** — each a named token set. Motion durations/easing are
  tokens too, so all transitions feel coherent.
Changing a token updates the whole app. If you're tempted to hardcode a value, add/extend a token
instead.

## 3. Layered structure (don't reach past a layer)
```
tokens (theme)         ← colors, type, spacing, motion — the only place raw values live
  └─ primitives        ← Button, Input, Select, Checkbox, Spinner, ProgressBar, Badge, Avatar, Toast…
       └─ composed      ← Card, Modal, Drawer, Table, Tabs, Toolbar, EmptyState, ErrorState, SkeletonBlock…
            └─ layouts   ← PageShell, AppSidebar, TopBar, SplitView, ContentContainer, Grid/Stack
                 └─ features ← screens compose the above; no raw styling here
```
Location: primitives + composed in `src/components/ui/`; layouts in `src/components/layout/`; feature
components in `src/features/<feature>/`. Features import down the stack, never the reverse.

## 4. Every interactive component declares all its states
A component is not done until it handles, visibly and consistently:
**default · hover · active/pressed · focus-visible · disabled · loading · error/invalid** (and
selected/checked where relevant). The three-state Listen button (idle / recording / processing) is the
canonical example — states are first-class, not afterthoughts. Loading and error states are mandatory,
not optional (see `04-loading-and-feedback.md`).

## 5. Variants over forks; composition over config
- Use a **variant system** (e.g. `class-variance-authority`) so a component exposes a small,
  documented set of `variant` × `size` × `tone` combinations rather than a sprawl of boolean props or
  copy-pasted components. New look needed → new variant, not a new near-duplicate component.
- Prefer **composition** (`<Card><Card.Header/>…`) over giant prop lists. Composable subcomponents
  beat 20-prop monoliths.
- Sensible defaults: a component used with no props should already look right.

## 6. Accessibility is part of the component, not a later pass
Build primitives on accessible foundations (Radix or equivalent): semantic HTML, keyboard
operability, visible `focus-visible` rings, correct ARIA roles/labels, and `prefers-reduced-motion`
honored in every animation. Verify charcoal/amber combinations meet WCAG AA contrast. An inaccessible
component is an incomplete component. (See `07-engineering-standards.md` for the a11y gate.)

## 7. Mobile-first & themable by construction
Heediq is a **mobile-first web app** (D-119/D-121 PWA): every screen is designed for a phone first,
then allowed to *grow* into tablet/desktop — never the reverse. Components adapt via tokens and layout
primitives, not per-screen breakpoint hacks. Charcoal is the dark-first base; if a light theme is ever
needed it's a token swap, so never hardcode a color that would block that.

**7.1 The no-horizontal-overflow invariant (non-negotiable).**
The page body must **never** scroll horizontally, at any supported width. `document.scrollWidth` must
not exceed the viewport at 320 / 375 / 768 / 1280 px. This is guarded by the Playwright responsive
harness (`e2e/responsive.e2e.ts`, `pnpm test:responsive`) and is a hard gate (`05-testing.md`). If
content is intrinsically wide (a long token, a data table, a code block), it wraps, truncates, or
scrolls **inside its own bounded container** — the page never does. A fixed-width child, an
un-shrinkable flex item (missing `min-w-0`), or a `text-nowrap` label are the usual culprits.

**7.2 Breakpoints — mobile-first, min-width only.**
Tailwind defaults: `sm` 640 / `md` 768 / `lg` 1024. Base (unprefixed) styles are the **phone** layout;
`sm:`/`md:`/`lg:` prefixes add capability as the screen grows. Never write desktop-first
(`max-*`-prefixed) styles as the default path — `max-*` is only for the deliberate *reflow-down*
patterns below (table → cards, stepper label collapse), where a component genuinely restructures on
small screens. Gutters and padding start small and step up (`px-4 sm:px-6 lg:px-8`), never the reverse.

**7.3 Navigation — bottom tab bar on mobile, top bar on desktop (D-152).**
Primary nav is a fixed **bottom tab bar** (`BottomTabBar`, `md:hidden`) on phones — thumb-reachable,
the platform-native mobile pattern — and a **top bar** (`TopBar`, `hidden md:flex`) on desktop. Both
render from the single `nav-items.ts` source so they never drift. A top-only menu is **not** an
acceptable mobile solution. Secondary/destructive actions (logout, account) live in **Settings**, not
in primary nav (D-152). Content sits in a `<main>` with `pb-bottom-nav md:pb-0` so the fixed bar never
overlaps the last row.

**7.4 The page frame is a primitive — `PageContainer` + `PageHeader`.**
Every authenticated screen wraps its content in `<PageContainer>` (centralises max-width, mobile-first
gutter, vertical rhythm) and leads with `<PageHeader title …>` for the `h1` + description + actions
row. **No page re-implements `mx-auto max-w-* p-8` by hand** — that's the layout equivalent of a raw
hex color under the golden rule. Pick the `size` by content type: `prose` (reading/forms), `md`,
`default` (lists), `wide` (dense/tables). The deliberate exceptions are genuine full-height split
layouts (e.g. the master/detail Context Library), which own their own frame.

**7.5 Tables reflow to cards on mobile (D-153).**
Data tables must not force horizontal scroll for primary content. Below `sm` (640px) the kit `Table`
**reflows to stacked cards**: each row becomes a bordered card, each cell a `label: value` line (pass
the column header as the `label` prop on `Table.Cell`). `overflow-x-auto` on a table is a desktop-only
affordance, never the mobile answer for primary content.

**7.6 Tap targets & safe areas.**
Interactive targets are **≥44×44px** on touch (Apple HIG / Material). Respect device safe areas: the
viewport is `viewport-fit=cover` and fixed/bottom elements use the `.pb-safe` / `.pb-bottom-nav`
utilities (`env(safe-area-inset-*)`) so nothing hides behind a home indicator or notch.

**7.7 Verify on real widths.**
Any UI change is checked at 320 / 375 / 768 / 1280 before it's done — via the Playwright harness for
the no-overflow gate, and visually via the `/dev/ui` gallery (which itself must pass at every width).

## 8. A living component gallery
Maintain a showcase where every component renders in isolation with all its variants and states
(Storybook, or a `/dev/ui` route guarded out of prod). This is how you (a) review the kit visually,
(b) catch drift, and (c) onboard. Adding a component without adding it to the gallery is incomplete.

## 9. Each kit component carries a README
Per `06-documentation.md`, a component folder has a short `README.md`: purpose, props/variants, the
states it supports, and a usage example. This is the human + Claude reference and prevents
re-inventing an existing component.

## 10. Performance & hygiene
- Keep primitives lightweight; avoid pulling heavy deps into a low-level component.
- No inline style objects recreated each render for static styles; memoize where it matters.
- Icons from one set (consistent stroke/size); no mixing icon libraries.
- One animation/transition convention (token-driven durations/easing) so motion feels unified.

---

## Definition of done for any UI work
- [ ] Built only from kit components + layout primitives; **zero bespoke visual styling in feature code**
- [ ] Page wrapped in `PageContainer` + `PageHeader` (not a hand-rolled `mx-auto max-w-* p-*` frame)
- [ ] Any new element added to the kit as a component/variant (not inlined) and to the gallery
- [ ] All relevant states present: default/hover/active/focus/disabled/**loading**/**error**
- [ ] Loading & feedback rules satisfied (`04-loading-and-feedback.md`)
- [ ] Keyboard-operable, focus-visible, AA contrast, reduced-motion respected
- [ ] **Mobile-first (§7): no horizontal overflow at 320/375/768/1280; tables reflow; ≥44px tap targets; safe areas respected**
- [ ] `pnpm test:responsive` passes (no-overflow harness)
- [ ] Tokens used for every color/space/type/radius/shadow/motion value — no hardcoded values
- [ ] Component README updated/created
