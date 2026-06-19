# Retrieval Pipeline

The retrieval pipeline runs as an n8n agentic workflow that processes user queries, retrieves relevant chunks, and generates grounded answers with citations.

**Owner**: M6 · **Workflow**: `n8n-workflows/retrieval-pipeline.json`

## Agentic Loop

```{mermaid}
flowchart TB
    Q["User query + history"] --> Planner["AI Agent · DeepSeek V4 Flash"]
    Planner --> Tools{"Select tool"}
    Tools -->|"search KB"| T1["search_knowledge_base"]
    Tools -->|"search uploaded"| T2["search_ephemeral"]
    Tools -->|"clarification needed"| T3["ask_clarifying_question"]
    Tools -->|"web context"| T4["web_lookup"]
    T1 & T2 & T4 --> Rerank["Voyage rerank-2.5"]
    Rerank --> Synth["Synthesize answer · DeepSeek V4 Flash"]
    Synth --> Check["Self-check · Gemini 3.5 Flash"]
    Check -->|"faithfulness ≥ 0.7"| Out["Return answer + citations"]
    Check -->|"< 0.7"| Retry["Retry · DeepSeek V4 Pro"]
    Retry --> Out
    T3 --> Out
```

## Tools Available to the Agent

### `search_knowledge_base`
1. Embed query using Voyage `voyage-4-large`
2. Cosine similarity search on `document_chunks` with `WHERE tenant_id = :tenant_id`
3. Rerank top results using Voyage `rerank-2.5`
4. Return top-K chunks with metadata (title, page number, score)

### `search_ephemeral`
Same as `search_knowledge_base` but queries `ephemeral_chunks` table. Only used when `include_ephemeral=true` (WhatsApp conversations with uploaded files).

### `ask_clarifying_question`
Returns early with a clarification question instead of attempting an answer. Used when the query is ambiguous or insufficient context is found.

### `web_lookup`
Optional tool (opt-in per tenant). Searches the web for additional context. Not used in default configuration.

## Answer Synthesis

The agent assembles retrieved chunks into a context window and generates an answer using DeepSeek V4 Flash with a system prompt that enforces:

- Citation format: `[Document Title, p.XX]`
- Grounding: only answer from retrieved context
- "I don't know" response when no relevant chunks found
- 3 follow-up questions per response

## Self-Check (Faithfulness Verification)

After answer generation, Gemini 3.5 Flash evaluates:

- Does every claim in the answer have support in the retrieved chunks?
- Returns a faithfulness score (0.0–1.0)

| Score | Action |
|:------|:-------|
| ≥ 0.7 | Accept and return |
| < 0.7 | Retry with DeepSeek V4 Pro (stronger model) |

The faithfulness score is stored on `chat_messages.faithfulness` and displayed in the UI as a color-coded badge.

## AI Model Stack

| Role | Model | Purpose |
|:-----|:------|:--------|
| Embedding | Voyage `voyage-4-large` | Query + document embedding (1024 dims) |
| Reranking | Voyage `rerank-2.5` | Re-score retrieved chunks |
| Generation | DeepSeek V4 Flash | Primary answer synthesis |
| Fallback | DeepSeek V4 Pro | Retry for low-faithfulness answers |
| Self-check | Gemini 3.5 Flash | Faithfulness verification |
| OCR | OpenAI `gpt-4o` | Scanned PDF text extraction |
