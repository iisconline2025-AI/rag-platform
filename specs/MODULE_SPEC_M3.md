# MODULE_SPEC_M3 — Backend: Document & Chat APIs

**Owner**: Member 3 | **Track**: Backend | **Branch**: `feat/admin-api`, `feat/chat-api`

## Role
File upload endpoint, document management, chat proxy to n8n with MOCK mode.
**Critical**: Ship `chat.py` with `MOCK_N8N=true` on Day 2 — this unblocks M4, M8, M9, M12.

## Day-by-Day Deliverables
| Day | Deliverable | Done? |
|---|---|---|
| 1 | Read `specs/openapi.yaml`. Understand n8n webhook contract. | ☐ |
| 2 | `backend/app/api/chat.py` with `MOCK_N8N=true` returning valid mock response | ☐ |
| 2 | `POST /admin/documents/upload` — save file, create DB record, trigger n8n | ☐ |
| 2 | `POST /admin/documents/url` — URL ingestion trigger | ☐ |
| 2 | `GET /admin/documents`, `GET /admin/documents/{id}`, `DELETE` | ☐ |
| 3 | Wire real n8n retrieval into `POST /chat/query` (disable mock) | ☐ |
| 3 | Conversation + ChatMessage models + endpoints | ☐ |
| 4 | Upload → ingestion flow working end-to-end | ☐ |
| 5–6 | Integration tests, bug fixes | ☐ |

## Files Owned
- `backend/app/api/admin.py`
- `backend/app/api/chat.py`
- `backend/app/services/n8n_client.py`

## MOCK_N8N Implementation (Day 2 priority)
```python
# backend/app/api/chat.py
import os
from fastapi import APIRouter, Depends
from app.core.dependencies import get_current_user

router = APIRouter()

MOCK_RESPONSE = {
    "answer": "Based on the uploaded documentation, here is the answer with details...",
    "sources": [{"document_id": "mock-uuid", "title": "Sample Manual", "chunk_text": "Relevant excerpt...", "page_number": 12, "score": 0.94}],
    "follow_up_questions": ["Can you explain more?", "What are the steps?", "Who should I contact?"],
    "metadata": {"model": "gpt-4o-mini", "retrieval_time_ms": 1200, "chunks_retrieved": 5}
}

@router.post("/query")
async def chat_query(request: ChatQueryRequest, current_user=Depends(get_current_user)):
    if os.getenv("MOCK_N8N", "false").lower() == "true":
        return MOCK_RESPONSE  # <-- ship this Day 2
    # real implementation below (Day 3)
    return await n8n_client.retrieve(...)
```

## n8n Client Service
```python
# backend/app/services/n8n_client.py
async def ingest(document_id, tenant_id, file_path, source_type): ...
async def retrieve(query, tenant_id, conversation_history, max_chunks=5): ...
```
- Uses `httpx.AsyncClient`
- Reads `N8N_RETRIEVE_WEBHOOK_URL`, `N8N_INGEST_WEBHOOK_URL` from config
- Raises `HTTPException(502)` if n8n returns non-200

## Acceptance Criteria
- [ ] `MOCK_N8N=true`: `POST /chat/query` returns valid mock response (Day 2)
- [ ] `POST /admin/documents/upload` saves file + returns 202 with document record
- [ ] Document status updates from `pending` → `completed` after n8n callback
- [ ] `GET /admin/documents` returns paginated list filtered by current tenant
- [ ] Integration test: upload PDF → query → get grounded answer
