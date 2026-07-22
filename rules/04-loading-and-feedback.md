# Loading & Feedback — The System Is Always Responsive

Principle: **the user is never left wondering what's happening.** Every wait is visible, every action
gets an acknowledgment, every outcome (success/error) is communicated. Heediq runs long jobs
(transcription, diarization, summarization), so this is core to the product feel, not polish.

All feedback is delivered through **kit components** (Spinner, ProgressBar, SkeletonBlock, Toast,
EmptyState, ErrorState — see `03-ui-kit.md`), never one-off markup.

---

## 1. No silent waits
Any async operation that can exceed ~300ms must show visible feedback. Nothing should ever appear
frozen. If you're awaiting something, the UI says so.

## 2. Page-level loading → skeletons, not blank screens
When a whole page/route is loading, show a **skeleton that mirrors the eventual layout** (lists,
cards, the transcript pane), not a generic centered spinner. Skeletons preserve layout, cut perceived
wait, and prevent layout shift when real content arrives. A top-of-page progress bar may accompany
route transitions.

## 3. Section / partial loading
For partial updates, load only the affected region (a card, a panel) with its own skeleton or inline
spinner — never block the whole screen for a local fetch.

## 4. Button & action loading state — and the double-submit guard, everywhere (D-120)
On any action that triggers async work, the trigger control enters its **loading state**: spinner +
disabled + **width preserved** (no layout jump), with label like "Saving…". The control is disabled
while pending so the action can't be **double-submitted**. The three-state Listen button (idle →
recording → processing) is the reference pattern.

**This double-submit guard is a general frontend rule, not a per-button opt-in.** Any interactive
element that triggers async work (button, form submit, link-triggered mutation) must ignore a
re-entrant trigger while its action is still pending — a rapid double-click/double-tap/double-Enter
never fires the handler twice. Use the shared `useAsyncAction` hook (`heediq-web/src/lib/useAsyncAction.ts`)
to implement this: it combines a synchronous `useRef` guard (blocks a re-entrant call before React
re-renders the disabled UI) with a `pending` state that drives the loading UI. For `<form>` submits,
call `e.preventDefault()` in a plain synchronous handler *before* invoking the guarded action — never
inside the guarded action itself, or a blocked re-entrant call skips `preventDefault()` and the
browser submits the form natively.

**Every appearing/disappearing visual state must animate, not snap.** Focus rings, error rings,
borders, and shadows are common offenders: Tailwind's `transition-colors` utility does **not** include
`box-shadow` or `opacity`, so a ring or a disabled-state dim will snap instantly unless the component's
transition class explicitly lists the properties (e.g. `transition-[border-color,box-shadow,opacity]`)
combined with the shared `duration-base`/`ease-brand` tokens (`tailwind.config.ts`, mirroring
`src/lib/motion.ts`'s duration/easing so CSS transitions and Framer Motion motion feel like one
system, D-117). Check this whenever a component's focus/error/disabled visual state is added or
changed — it's a common oversight, not an edge case.

## 5. Long-running jobs → determinate progress with stages, via the WS framework (D-111)
Transcription/summarization are long. Show **real progress**, not an endless indeterminate spinner:
a stage indicator (`queued → transcribing → diarizing → summarizing → ready`) and a percentage/bar
where the backend can report it. Surface the current stage in plain language. Reflect the actual
pipeline state **pushed over the WebSocket framework** (`heediq-web/src/lib/ws/`, `useWsEvent`,
D-061/D-109/D-110) — not polling, not faked. Every feature with async backend work registers a
`useWsEvent` handler (reusing `job_status` or adding a new `WsEventPayloadMap` event) to drive this;
this is a planning requirement (D-111, `01-development-workflow.md` Step 2), not a per-feature choice.

## 6. Context chat UI — hold to the ChatGPT/Claude.ai bar, not a generic form (D-138/D-139/D-145)
Chat is a flagship surface, not just another async form — benchmark it against ChatGPT/Claude.ai
directly, not against the rest of this app. Driven by the same WS event framework as §5
(`chat_delta`/`chat_complete`/`chat_failed`, D-145), but the bar for *feel* is higher because this is
where users spend sustained attention:
- **Stream token-by-token**, appending each `chat_delta` incrementally — never buffer and dump a
  whole response at once.
- **Show a "thinking" indicator** (animated ellipsis / pulsing dots) the instant the user's message
  sends, before the first delta arrives — the gap between send and first token is exactly the silent
  wait §1 forbids.
- **Auto-scroll while streaming, but stop the instant the user scrolls up** — never yank their
  viewport back down mid-read. Show a "jump to latest" affordance instead while they're scrolled up.
- **Render markdown incrementally** without flicker/re-layout as it completes (code blocks with syntax
  highlighting, lists, tables) — a half-formed code fence shouldn't visibly reflow when it closes.
- **A visible Stop control** while a turn is streaming; **Retry/Regenerate** on `chat_failed` or on a
  completed assistant turn — never leave a failed turn as a dead end (ties to §8's actionable-error
  rule).
- **Clear per-turn affordances**: copy-message, distinct user/assistant styling — no ambiguity about
  who said what while scrolling a long thread.
- **Input box**: auto-growing textarea, Enter-to-send / Shift+Enter-newline, send control disabled
  while a turn is in flight (the double-submit guard from §4 applies here too — one turn at a time).
- Message entrances animate via the shared motion system (`src/lib/motion.ts`, D-117) rather than
  popping in.

## 7. Optimistic UI where safe
For low-risk mutations (rename, toggle, reorder), update the UI immediately and **roll back on error**
with a toast. Don't use optimistic UI for operations where a wrong-then-corrected state would mislead
(payments, destructive actions) — those wait for the server.

## 8. Outcome feedback — success & error toasts
Every completed operation gives feedback:
- **Success** — a brief, non-blocking toast/inline confirmation ("Recording saved", "Pushed to
  Jira").
- **Error** — a clear, **actionable** toast/inline message: what failed, what to do, and a **Retry**
  where applicable. Never swallow an error into a blank screen or a silent no-op.

## 9. Designed empty states (distinct from loading)
Empty ≠ loading. When there's genuinely no data, show a designed `EmptyState` with a short
explanation and a primary action ("No recordings yet — Start your first recording"), not a bare blank
region.

## 10. Designed error states for every data fetch
Every data-loading surface has three branches: **loading (skeleton) · success (content) · error
(ErrorState with Retry)**. A failed fetch must never leave the user staring at an empty container.

## 11. Perceived-performance details
- **Instant click feedback** (<100ms): the control reacts immediately (press state) even before the
  request resolves.
- **Spinner delay threshold**: for very fast operations, delay showing a spinner ~150–200ms so it
  doesn't flash; once shown, keep it up a **minimum** time (~400ms) to avoid flicker.
- **Stale-while-revalidate**: show cached data immediately with a subtle "refreshing" indicator while
  fresh data loads, rather than a full skeleton on every revisit.
- **No layout shift**: reserve space for content that's loading (skeletons/placeholders sized to the
  real thing).

## 12. Global async conventions
- Use a server-state library (e.g. TanStack Query) so loading/error/refetch states are consistent and
  cached app-wide rather than hand-rolled per screen.
- Centralize toast handling (one Toaster) and error normalization so every failure renders the same
  way.
- For very long jobs, the user can navigate away and be notified on completion (toast / badge);
  progress survives navigation.

---

## Definition of done for any data/async UI
- [ ] Loading state visible (skeleton for pages/sections, button-loading for actions)
- [ ] Long jobs show staged, determinate progress reflecting real backend state
- [ ] Success feedback present; error feedback present, actionable, with Retry where applicable
- [ ] Empty state and error state both designed (no blank screens)
- [ ] No double-submit; no layout shift; spinner delay/min-display applied
- [ ] All feedback rendered via kit components, not one-off markup
- [ ] For Context chat specifically: streams token-by-token, shows a thinking indicator pre-first-token,
      auto-scroll respects manual scroll-up, Stop/Retry present, feels on par with ChatGPT/Claude.ai (§6)
