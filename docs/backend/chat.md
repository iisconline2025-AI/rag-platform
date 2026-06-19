# Chat API

The chat module handles user queries against the knowledge base and conversation management.

**Owner**: M3 · **File**: `backend/app/api/chat.py`

## Endpoints

### POST `/chat/query`

Submit a natural language question and receive a grounded answer with citations.

:::{tip}
Set `MOCK_N8N=true` in your `.env` to get canned responses without a running n8n instance. This is useful for frontend development.
:::

**Request Body**:
```json
{
  "query": "How do I reset the device?",
  "conversation_id": "uuid (optional — creates new if omitted)"
}
```

**Response** (`200 OK`):
```json
{
  "answer": "To reset the device, press and hold the Start button for 3 seconds... [Manual, p.12]",
  "sources": [
    {
      "document_id": "uuid",
      "title": "Product Manual",
      "chunk_text": "Press and hold the Start button...",
      "page_number": 12,
      "score": 0.94
    }
  ],
  "follow_up_questions": [
    "What happens after a factory reset?",
    "Will I lose my saved settings?",
    "How do I update the firmware?"
  ],
  "faithfulness": 0.92,
  "requires_clarification": false,
  "conversation_id": "uuid",
  "metadata": {
    "model": "deepseek-v4-flash",
    "retrieval_time_ms": 1100,
    "chunks_retrieved": 5
  }
}
```

### GET `/chat/conversations`

List all conversations for the current user.

### GET `/chat/conversations/{id}`

Get full message history for a conversation.

### DELETE `/chat/conversations/{id}`

Delete a conversation and its messages.

## Query Flow

1. User submits query via any channel (Web, WhatsApp, MCP)
2. FastAPI validates JWT, extracts `tenant_id` and `user_id`
3. Creates or loads `Conversation` record
4. Stores user message in `chat_messages`
5. Calls n8n retrieval webhook with query + conversation history
6. n8n returns grounded answer with sources and faithfulness score
7. Stores assistant message + sources in `chat_messages`
8. Returns response to client

## Mock Mode

When `MOCK_N8N=true`, the endpoint returns a canned response:

```python
{
    "answer": "Based on the uploaded documentation, here is your answer. "
              "This is mock mode — set MOCK_N8N=false to get real RAG responses. [Sample Manual, p.12]",
    "sources": [
        {
            "document_id": "00000000-0000-0000-0000-000000000001",
            "title": "Sample Product Manual",
            "chunk_text": "Sample relevant excerpt from the document...",
            "page_number": 12,
            "score": 0.94,
        }
    ],
    "follow_up_questions": ["Can you give more details?", "What are the next steps?", "Who should I contact?"],
    "conversation_id": "00000000-0000-0000-0000-000000000099",
    "metadata": {"model": "gpt-4o-mini", "retrieval_time_ms": 1200, "chunks_retrieved": 5, "mock": True},
}
```

:::{admonition} Not Yet Implemented
:class: warning

The mock response does **not** include `faithfulness` or `requires_clarification` fields. These will be added when M3 implements the real n8n retrieval integration. The full response shape (with faithfulness score) is defined in `ARCHITECTURE.md` webhook contracts.
:::
