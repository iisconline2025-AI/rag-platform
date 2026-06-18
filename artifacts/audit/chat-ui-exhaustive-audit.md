# Chat UI — Exhaustive Audit (Pre-PR)

**Date:** 2026-06-19
**Branch:** `feat/chat-ui` @ `5b7a912`
**Scope:** Read-only audit. No files edited except this report.
**Docs read:** `CLAUDE.md`, `PROJECT_SPEC.md`, `ARCHITECTURE.md`, `SKILLS.md`, `TEAM_WORKFLOW.md`, `specs/openapi.yaml` (chat paths/schemas), `specs/MODULE_SPEC_M9.md`, `frontend/chat/types/chat.ts`, `frontend/src/lib/chat/chatApi.ts`, all of `frontend/src/app/chat/`, all of `frontend/src/components/chat/`, `frontend/package.json`, `frontend/vitest.config.ts`, `frontend/vitest.setup.ts`, chat test files.

---

## 1. Consistency findings, by checklist item

**1. `/chat`, `/chat/new`, `/chat/[conversationId]`** — OK. `/chat/page.tsx` redirects to `/chat/new` (matches `MODULE_SPEC_M9.md` "Key Pages" exactly). `/chat/new` starts blank, sends with `conversation_id: null`, keeps the returned id in local state. `/chat/[conversationId]` loads via `getConversation()` with loading/error+retry states. *Non-blocking:* after the first send on `/chat/new`, the URL never updates to `/chat/[id]` — a refresh loses the in-memory thread (it's still reachable from the sidebar, just not at the URL the user is sitting on).

**2. Conversation list/sidebar** — OK. `ConversationList.tsx` calls `listConversations()`, shows title (falls back to "Untitled conversation") + formatted `created_at`, highlights the active id, "New Chat" → `/chat/new`, each item → `/chat/[id]`, delete → `deleteConversation()` + reload, loading/error/empty states all handled. Rendered in `ChatLayout`'s sidebar (desktop static + mobile drawer).

**3. Message input and message rendering** — OK. `MessageInput.tsx`: single-row textarea, Cmd/Ctrl+Enter submits, disabled while sending. `MessageList.tsx` maps to `MessageBubble`. Matches acceptance criteria for send/typing-indicator behavior.

**4. Markdown rendering** — OK. Assistant messages render via `react-markdown` + `rehype-highlight`; user messages stay plain text. Links forced to `target="_blank" rel="noreferrer"`. `rehype-raw` (raw HTML passthrough, an XSS risk) was deliberately *not* added despite being listed as a Day-1 suggestion in `MODULE_SPEC_M9.md` — correct call. *Non-blocking:* no GFM (tables/strikethrough) support — listed as "nice-to-have" in the module spec, not a required acceptance item.

**5. Citations panel — ⚠ BLOCKER.** `CitationsPanel` itself is correct (title/page/excerpt/score, collapsible, no fake citation on empty). But both `/chat/new` and `/chat/[conversationId]` only render `CitationsPanel`/`FaithfulnessBadge`/`ClarificationBanner` for `lastResponse` (the single most recent API response) **below the entire message list** — not per message. `ChatMessageOut` (per `openapi.yaml`) already carries `sources`, `faithfulness`, and `requires_clarification` on *every* message, but `MessageBubble`/`MessageList` never read those fields. Net effect: as soon as a second turn is sent, the first answer's citations/grounding badge become permanently inaccessible in the UI, even though the data exists. This conflicts with `CLAUDE.md`'s "every answer must cite a source chunk" and `PROJECT_SPEC.md`'s "Citation coverage ≥ 90% of answers" success criterion — the backend may satisfy it, but the UI doesn't expose it for any answer except the latest. **Recommend fixing before merge**: move citation/badge/banner rendering into `MessageBubble` (per-message), driven by `message.sources` / `message.faithfulness` / `message.requires_clarification`, instead of the page-level `lastResponse` state.

**6. Faithfulness badge thresholds** — OK. `score ≥ 0.85` → green "Grounded"; `0.70 ≤ score < 0.85` → amber "Partially grounded"; `score < 0.70` → red "Low confidence"; `null`/`undefined` → "Not scored". Matches `MODULE_SPEC_M9.md`'s stated bands and `SKILLS.md`'s RAGAS faithfulness target (≥0.85). Covered by 4 passing unit tests.

**7. Clarification banner** — OK, renders only when `requires_clarification === true`, returns `null` otherwise. Same latest-only visibility limitation as #5 (not a separate root cause). *Minor, non-blocking:* `MODULE_SPEC_M9.md`'s Day-4 plan says clarification should also "highlight the badge red" — `FaithfulnessBadge` only takes `score`, not a clarification flag, so this cross-component coupling was never implemented. Low severity; the banner already flags the situation independently.

**8. Follow-up chips** — OK. Caps at 3, returns `null` if empty, click calls `onSelect(question)` → same `handleSend` used for normal submission, so it sends in the same conversation. Covered by passing unit tests. Same "latest-turn-only" visibility as #5, but stale follow-ups for an old answer are less valuable anyway — low severity.

**9. Retry behavior** — OK. Both pages split `handleSend` (append user bubble + call `runQuery`) from `runQuery` (API call + append assistant message) from `handleRetry` (calls `runQuery(pendingQuery)` directly). Confirmed: retry cannot re-append a duplicate user message, and the assistant message appends at most once per resolved attempt. Identical pattern in both pages.

**10. Auth guard** — OK. `ChatAuthGuard.tsx` mirrors `components/admin/AuthGuard.tsx`'s logic via the shared `useAuth()` context (not a forbidden cross-module import — `components/admin/` is M8-owned, so a parallel M9 copy was created instead). Wraps the *entire* return of both pages, so `ConversationList`'s `listConversations()` call never fires pre-auth. Confirmed `openapi.yaml`'s top-level `security:` applies to all `/chat/*` paths (no override), so the guard is contractually justified. Pre-existing shared limitation (token-presence-only check, no backend verification) is inherited from the admin pattern, not introduced by M9.

**11. Mobile responsiveness** — OK, with one explicitly-deferred item. Sidebar is now a slide-over drawer (hamburger + overlay + close button) below `md:`, mirroring Admin's pattern — previously it was `hidden md:flex` with no way to ever open it on mobile. `MessageBubble` got `break-words` so long unbroken tokens can't overflow a 375px viewport; code blocks already had `overflow-x-auto`. *Non-blocking:* the drawer is partial-width (240px over a backdrop), not literally "full-screen" as `MODULE_SPEC_M9.md`'s Day-6 plan describes — consistent with the one existing reusable pattern in the codebase (Admin's drawer), just not a literal match to that wording. *Known, explicitly-deferred gap:* dark mode toggle (a `MODULE_SPEC_M9.md` acceptance-criteria checkbox) is **not implemented**. `tailwind.config.ts` declares `darkMode: 'class'` but there is no `ThemeProvider`, toggle, or any `dark:` class anywhere in the app (Admin UI included) — this was raised earlier in this branch's work and the explicit instruction at the time was to report it as a shared-app gap rather than build new global theme infra. Still outstanding against the module's own acceptance list.

**12. Tests added** — OK for the stated minimal-test goal. `vitest.config.ts` + `vitest.setup.ts` (jsdom, RTL, explicit `afterEach(cleanup)`), `package.json` `"test": "vitest run"`. Two colocated files: `FaithfulnessBadge.test.tsx` (4 threshold cases) and `ChatPanels.test.tsx` (citations empty-state, follow-up cap + click). **Re-run for this audit: 2 files / 7 tests, all passing.** *Non-blocking follow-up:* no test yet for retry-no-duplicate-message, markdown rendering, `ChatAuthGuard` redirect, or a page-level send-flow integration test — all were out of scope for the phases that added them.

**13. No fake citations** — OK. `CitationsPanel` only ever renders from its `sources` prop; the empty branch is a literal "No citations available" string, never a fabricated source object.

**14. No `POST /chat/conversations` usage** — OK. Grepped all chat frontend files; the only matches are comments in `chatApi.ts`/`chat.ts` *documenting that the endpoint doesn't exist*. Confirmed absent from `openapi.yaml` too.

**15. No `/chat/conversations/{id}/messages` usage** — OK. `getConversation()` calls only `/chat/conversations/{id}`; `openapi.yaml`'s response schema embeds `messages` directly via `allOf`, matching usage exactly.

**16. No hardcoded provider/model names** — OK. Grepped for `gpt-4o-mini`, `deepseek`, `voyage`, `gemini`, `claude`, `anthropic`, `text-embedding` across all chat frontend files — zero hits. `ChatQueryResponse.metadata.model` exists in the type contract but is never read or rendered by any chat component, so there's no surface for this to regress on.

**17. No "no hallucination" overclaim** — OK within M9's scope. Grepped all chat frontend code/comments/tests for "hallucinat" — zero hits. (`PROJECT_SPEC.md` itself uses "no hallucinations" in its root one-line summary — that's outside `frontend/src/app/chat/`, `frontend/src/components/chat/`, `frontend/src/lib/chat/`, `frontend/chat/`, so out of this audit's file scope and not an M9 finding.)

**18. No backend/admin/webhook/WhatsApp/Slack/Teams scope creep** — OK. Every change across this branch's chat work touched only `frontend/src/app/chat/`, `frontend/src/components/chat/`, `frontend/chat/`, `frontend/vitest.*`, and `frontend/package.json` (dependency/script additions only). Confirmed via grep for any reference to `components/admin`, `app/admin`, `webhooks`, `whatsapp`, `slack`, `teams` inside the chat scope — zero hits.

---

## Final PR Readiness Audit

### Verdict: **CONDITIONAL GO**

### Blockers (fix before merging to `dev`)
1. **Per-message grounding UI (item 5).** Citations, faithfulness badge, and clarification banner only reflect the *latest* turn (`lastResponse` page state), not each message, even though `ChatMessageOut.sources` / `.faithfulness` / `.requires_clarification` are already present per message from the API. In any conversation with 2+ turns, earlier answers' citations become inaccessible in the UI. Fix: render these from `message.*` inside `MessageBubble`/`MessageList` instead of a page-level "last response" panel.

### Non-blocking issues (track as follow-up, do not block this PR)
- `/chat/new` doesn't navigate to `/chat/[id]` after the first send creates a real conversation (URL stays on `/chat/new`).
- No GFM (tables/strikethrough) markdown support — listed as nice-to-have only.
- Clarification doesn't force-highlight the faithfulness badge red, per `MODULE_SPEC_M9.md`'s Day-4 plan wording (the banner already covers this independently).
- Mobile sidebar drawer is partial-width, not literally full-screen as the module spec's Day-6 plan describes.
- **Dark mode toggle is not implemented** — an explicit `MODULE_SPEC_M9.md` acceptance box, knowingly deferred earlier in this branch's work as a shared-app-shell gap (no `ThemeProvider`/toggle exists anywhere in the app, including Admin UI). Recommend a tracked follow-up ticket rather than blocking this PR.
- Test coverage is minimal by design (7 tests, 2 files); no coverage yet for retry/markdown/auth-guard/page-integration behavior.

### Files audited
Docs: `CLAUDE.md`, `PROJECT_SPEC.md`, `ARCHITECTURE.md`, `SKILLS.md`, `TEAM_WORKFLOW.md`, `specs/openapi.yaml`, `specs/MODULE_SPEC_M9.md`.
Code: `frontend/chat/types/chat.ts`, `frontend/src/lib/chat/chatApi.ts`, `frontend/src/app/chat/page.tsx`, `frontend/src/app/chat/new/page.tsx`, `frontend/src/app/chat/[conversationId]/page.tsx`, and all 15 files in `frontend/src/components/chat/` (`ChatLayout`, `ChatAuthGuard`, `ConversationList`, `MessageList`, `MessageBubble`, `MessageInput`, `TypingIndicator`, `ChatEmptyState`, `ChatErrorState`, `ClarificationBanner`, `CitationsPanel`, `FaithfulnessBadge`, `FollowUpChips`, plus the two test files).
Config: `frontend/package.json`, `frontend/vitest.config.ts`, `frontend/vitest.setup.ts`.

### Tests / lint status (re-run for this audit)
- `npx eslint` across `src/app/chat src/components/chat src/lib/chat chat/types vitest.config.ts vitest.setup.ts` → **0 errors/warnings**.
- `npm test` (`vitest run`) → **2 test files, 7/7 tests passing**.

### Exact PR checklist
- [ ] Fix blocker #1 (per-message citations/badge/banner) or explicitly accept the gap with M1 sign-off before opening the PR.
- [x] PR targets `dev`, not `main` (per `TEAM_WORKFLOW.md`).
- [x] PR title format `feat(chat): ...` (matches existing commit history on this branch).
- [x] Matches `specs/openapi.yaml` exactly — no `POST /chat/conversations`, no `/chat/conversations/{id}/messages`, request/response field names/types verified against schema.
- [x] At least one passing test (`npm test` → 7/7).
- [x] `npm run lint` clean on touched chat files.
- [ ] `npm run typecheck` / `npm run build` — not run as part of this audit (out of stated scope for the phases that built this); recommend running once before opening the PR.
- [x] No secrets committed (no `.env` touched).
- [x] No edits outside `frontend/src/app/chat/`, `frontend/src/components/chat/`, `frontend/src/lib/chat/`, `frontend/chat/`, plus minimal `frontend/package.json`/`vitest.*` test-infra additions.
- [ ] PR description includes: what it does, how to test (e.g. `MOCK_N8N=true` backend + `npm run dev`), and test output/screenshot, per `TEAM_WORKFLOW.md` PR Rules.
- [ ] Note the dark-mode and per-message-citation gaps explicitly in the PR description so reviewers aren't surprised.
