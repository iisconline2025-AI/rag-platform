# MODULE_SPEC_M9 — Frontend: Chat Portal

**Owner**: Member 9 | **Track**: Frontend | **Branch**: `feat/chat-ui`

## Role
Next.js ChatGPT-style interface for querying the knowledge base with grounded answers and citations.

## Day-by-Day Deliverables
| Day | Deliverable | Done? |
|---|---|---|
| 1 | Wireframe chat layout. Study M3's mock response shape. | ☐ |
| 2 | Chat layout: sidebar (conversation list) + main chat area | ☐ |
| 2 | Message input component: textarea, send button, keyboard shortcuts | ☐ |
| 2 | Message display: user/assistant bubbles + Markdown rendering | ☐ |
| 3 | Source citations: collapsible panel with chunk text + page numbers + scores | ☐ |
| 3 | Follow-up question chips (clickable → auto-fills input) | ☐ |
| 3 | Conversation management: new chat, auto-title, load history | ☐ |
| 4 | Wire to real `POST /chat/query` endpoint | ☐ |
| 5 | Typing indicator (skeleton while waiting for n8n) | ☐ |
| 5 | Dark mode + mobile responsive | ☐ |
| 6 | Polish, search across conversations | ☐ |

## Files Owned
- `frontend/src/app/chat/`
- `frontend/src/components/chat/`

## Key Pages
```
/chat                  → redirects to /chat/new
/chat/new              → blank conversation
/chat/[conversation_id] → loaded conversation
```

## Component Structure
```
src/components/chat/
  ChatLayout.tsx        → sidebar + main area wrapper
  ConversationList.tsx  → list of past conversations
  MessageList.tsx       → scrollable message history
  MessageBubble.tsx     → single user/assistant bubble
  CitationsPanel.tsx    → collapsible citations accordion
  FollowUpChips.tsx     → clickable follow-up suggestions
  MessageInput.tsx      → textarea + send button
  TypingIndicator.tsx   → animated dots while waiting
```

## Mock Data Shape (from M3)
```typescript
interface ChatQueryResponse {
  answer: string
  sources: Array<{
    document_id: string
    title: string
    chunk_text: string
    page_number: number | null
    score: number
  }>
  follow_up_questions: string[]
  conversation_id: string
  metadata: { model: string; retrieval_time_ms: number; chunks_retrieved: number }
}
```

## Citations Panel Design
```
[📄 Source 1] Product Manual — p.12 (score: 0.94)    ▼
  "...the relevant excerpt from the document showing the
   context that was used to generate this answer..."

[📄 Source 2] Quick Start Guide — p.3 (score: 0.87)  ▼
  "...second relevant excerpt..."
```

## Acceptance Criteria
- [ ] Message sent → answer displayed with Markdown formatting
- [ ] Citations panel shows document title + page + excerpt (collapsible)
- [ ] Follow-up chips appear below each answer; clicking one sends the query
- [ ] New conversation created on first message if no conversation_id
- [ ] Conversation history loads on sidebar
- [ ] Typing indicator shown while waiting for response
- [ ] Works on mobile (responsive at 375px width)
- [ ] Dark mode toggle working
