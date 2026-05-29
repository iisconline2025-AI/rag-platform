# MODULE_SPEC_M6 — n8n: Retrieval + Generation Pipeline

**Owner**: Member 6 | **Track**: n8n | **Branch**: `feat/n8n-retrieve`
**⚠️ CRITICAL PATH** — Must be complete by end of Day 3.

## Role
Build the RAG retrieval n8n workflow: webhook → embed query → pgvector search → LLM call → citations → response.

## Day-by-Day Deliverables
| Day | Deliverable | Done? |
|---|---|---|
| 1 | Read n8n contract spec. Set up n8n alongside M5. Understand pgvector query. | ☐ |
| 2 | Webhook trigger + OpenAI `/embeddings` HTTP Request node | ☐ |
| 2 | Postgres pgvector cosine similarity query node | ☐ |
| 3 | Context assembly Code node | ☐ |
| 3 | System prompt engineering (customer support persona) | ☐ |
| 3 | OpenAI `/chat/completions` HTTP Request node | ☐ |
| 3 | Source citation extraction Code node | ☐ |
| 4 | Follow-up question generation (add to LLM prompt) | ☐ |
| 4 | Conversation history inclusion in context | ☐ |
| 5 | Prompt tuning — improve answer quality and citation format | ☐ |
| 6 | Export `n8n-workflows/retrieval-pipeline.json` | ☐ |

## Files Owned
- `n8n-workflows/retrieval-pipeline.json`

## Workflow Architecture
```
[Webhook Trigger] ← POST /webhook/retrieve
  {query, tenant_id, conversation_history, max_chunks}
        │
        ▼
[HTTP Request: OpenAI /embeddings]
  POST https://api.openai.com/v1/embeddings
  {input: query, model: "text-embedding-3-small"}
        │
        ▼
[Postgres: pgvector similarity search]
  SELECT id, content, document_id, page_number,
         1 - (embedding <=> $query_embedding::vector) AS score
  FROM document_chunks
  WHERE tenant_id = $tenant_id
  ORDER BY embedding <=> $query_embedding::vector
  LIMIT $max_chunks
        │
        ▼
[Code: Build Prompt]
  context = top chunks formatted as numbered list
  history = last 10 conversation_history messages
  system_prompt = (see below)
        │
        ▼
[HTTP Request: OpenAI /chat/completions]
  POST https://api.openai.com/v1/chat/completions
  {model: "gpt-4o-mini", messages: [system, ...history, user_query], max_tokens: 1500}
        │
        ▼
[Code: Format Response]
  Extract answer text
  Map citations: match answer to source chunks
  Generate follow-up questions (in same LLM call)
        │
        ▼
[Respond to Webhook] → N8nRetrieveResponse JSON
```

## System Prompt
```
You are a helpful customer support assistant. Answer questions ONLY using
the provided context documents. If the answer is not in the context,
say "I don't have enough information in the uploaded documents to answer this question."

Always cite your sources by referencing the document title and page number.
Format citations as [Document Title, p.N].

After your answer, generate exactly 3 follow-up questions the user might ask.
Format them as JSON: {"follow_up_questions": ["q1", "q2", "q3"]}
```

## Response Schema
```json
{
  "answer": "To reset the device, press and hold the power button for 5 seconds [Manual, p.12].",
  "sources": [
    {"document_id": "uuid", "title": "Product Manual", "chunk_text": "...", "page_number": 12, "score": 0.94}
  ],
  "follow_up_questions": ["What if the reset fails?", "Where is the reset button?", "How long does reset take?"],
  "metadata": {"model": "gpt-4o-mini", "retrieval_time_ms": 1200, "chunks_retrieved": 5}
}
```

## Acceptance Criteria
- [ ] Query → embedded → pgvector search returns relevant chunks (test with 10 queries)
- [ ] LLM answer is grounded (does not hallucinate beyond context)
- [ ] Citations mapped correctly to source chunks
- [ ] 3 follow-up questions generated per response
- [ ] Conversation history included in LLM context
- [ ] `tenant_id` filter applied — cross-tenant leakage = 0
- [ ] Export `n8n-workflows/retrieval-pipeline.json` committed to repo
