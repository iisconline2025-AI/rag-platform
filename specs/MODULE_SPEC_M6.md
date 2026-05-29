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

---

## ?? Locked Scope Update (M1 / 29-May)

**Agentic loop**: The retrieval workflow uses n8n's **AI Agent node** with these tools:
1. `search_knowledge_base` � Voyage embed ? pgvector kNN(top 20) ? Voyage rerank ? top 5 chunks
2. `search_ephemeral` � same as above but on `ephemeral_chunks` (filter by `conversation_id`)
3. `ask_clarifying_question` � returns `requires_clarification=true` early
4. `web_lookup` � optional, per-tenant opt-in

**Models** (locked):
- Generation: **DeepSeek V4 Flash** via OpenAI-compatible base URL `https://api.deepseek.com`
- Self-check: **Gemini 3.5 Flash** � returns 0�1 faithfulness score
- Fallback: if faithfulness < 0.7 ? retry once with **DeepSeek V4 Pro**

**Output contract** (must match `specs/openapi.yaml` `ChatQueryResponse`):
```json
{
  "answer": "...",
  "sources": [...],
  "follow_up_questions": [...],
  "faithfulness": 0.92,
  "requires_clarification": false,
  "metadata": { "model": "deepseek-v4-flash", ... }
}
```

See [`n8n-workflows/retrieval-pipeline.json`](../n8n-workflows/retrieval-pipeline.json) for the scaffold M1 committed.


---
<!-- AUTO-APPENDED:SKILLS-V1 -->
## Skills Required
- **Must-have:** n8n LangChain nodes (`@n8n/n8n-nodes-langchain.agent`), tool-calling agents, Postgres + pgvector kNN queries, Voyage rerank API, Google Gemini API, DeepSeek API (OpenAI-compatible).
- **Nice-to-have:** Prompt engineering for grounded answers, faithfulness scoring, fallback chains.

## Detailed Step-by-Step Plan
### Day 1 — Import & Credentials
1. Import `n8n-workflows/retrieval-pipeline.json`.
2. Add credentials: `DeepSeekAuth` (Bearer DEEPSEEK_API_KEY, base URL `https://api.deepseek.com`), `GeminiAuth`, `VoyageAuth` (reuse M5's).

### Day 2 — Query Embed + Retrieval Tool
3. Webhook `/retrieve` POST → receives `{query, tenant_id, conversation_history, max_chunks}`.
4. HTTP "Embed Query": Voyage embeddings with `input_type: "query"`.
5. Postgres "Search KB": `SELECT chunk_id, document_id, text, page_number, 1 - (embedding <=> ) AS score FROM document_chunks WHERE tenant_id =  ORDER BY embedding <=>  LIMIT 20`.
6. Postgres "Search Ephemeral": same against `ephemeral_chunks` filtered by `conversation_id` and `expires_at > NOW()`.

### Day 3 — Rerank + Agent
7. HTTP "Voyage Rerank": POST `https://api.voyageai.com/v1/rerank` `{query, documents:[chunk_texts], model: "rerank-2.5", top_k: 5}`.
8. LangChain Agent node:
   - LLM: DeepSeek V4 Flash (HTTP creds, model=`deepseek-chat`).
   - System prompt: "You are a grounded assistant. Cite sources as [doc_title, p.X]. If chunks don't answer, set requires_clarification=true."
   - Tools: `search_kb`, `search_ephemeral`, `ask_clarifying_question`, `web_lookup` (stretch).

### Day 4 — Self-Check Loop
9. HTTP "Gemini Faithfulness": POST `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent` with prompt scoring (0-1) whether answer is supported by chunks.
10. IF node `faithfulness < 0.7` → branch to DeepSeek V4 Pro retry (model=`deepseek-reasoner`) with stricter prompt.

### Day 5 — Output Contract
11. Function "Format Response": emit JSON `{answer, sources:[{document_id, title, chunk_text, page_number, score}], faithfulness, requires_clarification, follow_up_questions:[3], metadata:{model, retrieval_time_ms, chunks_retrieved}}`.
12. Respond to Webhook node.

### Day 6 — Test + Export
13. Manually trigger with sample queries. Verify citation accuracy. Export workflow → overwrite JSON → commit.

## Learning Resources
- n8n AI Agent node: https://docs.n8n.io/integrations/builtin/cluster-nodes/root-nodes/n8n-nodes-langchain.agent/
- DeepSeek API: https://api-docs.deepseek.com/
- Gemini API: https://ai.google.dev/gemini-api/docs
- pgvector kNN: https://github.com/pgvector/pgvector#querying
