"""
Chat API routes — query (with MOCK_N8N mode), conversations.
Owner: M3 — implement route bodies.
CRITICAL: Ship MOCK_N8N=true response on Day 2 to unblock M4, M8, M9, M12.
"""
import os
from fastapi import APIRouter, HTTPException
from app.core.config import settings
from app.services import n8n_client

router = APIRouter()

# ── Mock response shape — matches real n8n response ───
MOCK_RESPONSE = {
    "answer": "Based on the uploaded documentation, here is your answer. "
              "This is mock mode — set MOCK_N8N=false to get real RAG responses. [Sample Manual, p.12]",
    "sources": [
        {
            "document_id": "00000000-0000-0000-0000-000000000001",
            "title": "Sample Product Manual",
            "chunk_text": "Sample relevant excerpt from the document used to generate this answer.",
            "page_number": 12,
            "score": 0.94,
        }
    ],
    "follow_up_questions": [
        "Can you give more details?",
        "What are the next steps?",
        "Who should I contact?",
    ],
    "conversation_id": "00000000-0000-0000-0000-000000000099",
    "metadata": {"model": "gpt-4o-mini", "retrieval_time_ms": 1200, "chunks_retrieved": 5, "mock": True},
}


@router.post("/query", summary="Send a query — returns grounded answer with citations")
async def chat_query(request: dict):
    """
    M3: Implement:
    1. Extract query, conversation_id, tenant_id from request + current_user
    2. Load conversation history from DB (last 10 messages)
    3. If MOCK_N8N=true: return MOCK_RESPONSE
    4. Else: call n8n_client.retrieve(query, tenant_id, history)
    5. Save user message + assistant response to chat_messages
    6. Return ChatQueryResponse
    """
    if settings.MOCK_N8N:
        return MOCK_RESPONSE
    # TODO M3: implement real retrieval
    raise HTTPException(status_code=501, detail="M3: implement real n8n retrieval (disable MOCK_N8N)")


@router.get("/conversations", summary="List conversations")
async def list_conversations():
    """M3: Return conversations for current user."""
    raise HTTPException(status_code=501, detail="M3: implement conversation list")


@router.get("/conversations/{conversation_id}", summary="Get conversation with messages")
async def get_conversation(conversation_id: str):
    """M3: Return conversation + all messages."""
    raise HTTPException(status_code=501, detail="M3: implement get conversation")


@router.delete("/conversations/{conversation_id}", status_code=204)
async def delete_conversation(conversation_id: str):
    """M3: Delete conversation and all messages."""
    raise HTTPException(status_code=501, detail="M3: implement delete conversation")
