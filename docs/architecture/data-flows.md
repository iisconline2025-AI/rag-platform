# Data Flows

## Two Upload Paths

```{mermaid}
flowchart TB
    subgraph Admin["Admin Persistent Upload"]
        A1["Admin uploads PDF (≤ 25 MB)"] --> A2["POST /admin/documents/upload"]
        A2 --> A3["Validate MIME + magic bytes + quota"]
        A3 --> A4["Save to /uploads"]
        A4 --> A5["Trigger n8n /webhook/ingest"]
        A5 --> A6["Chunks → document_chunks"]
        A6 --> A7["Available to ALL tenant users FOREVER"]
    end

    subgraph Chat["WhatsApp Ephemeral Upload"]
        B1["User sends PDF in WhatsApp (≤ 10 MB)"] --> B2["Twilio webhook → FastAPI"]
        B2 --> B3["Validate + save to /tmp"]
        B3 --> B4["Trigger n8n /webhook/ingest-ephemeral"]
        B4 --> B5["Chunks → ephemeral_chunks (TTL=1h)"]
        B5 --> B6["Scoped to ONE conversation, auto-purged"]
    end
```

| Aspect | Admin Upload | WhatsApp Upload |
|:-------|:------------|:----------------|
| Max size | 25 MB | 10 MB |
| Persistence | Forever (`document_chunks`) | 1 hour (`ephemeral_chunks`) |
| Scope | All users in tenant | Single conversation only |
| Cleanup | Manual delete via UI | Hourly cron: `cleanup_ephemeral.py` |
| Counts toward quota | Yes (1 GB/tenant) | No |

## Agentic Retrieval Loop

```{mermaid}
flowchart TB
    Q["User query"] --> Planner["AI Agent · DeepSeek V4 Flash"]
    Planner --> Tools{"Pick tool"}
    Tools -->|"search KB"| T1["search_knowledge_base\nVoyage embed + pgvector + rerank"]
    Tools -->|"search uploaded"| T2["search_ephemeral\nsame flow on ephemeral_chunks"]
    Tools -->|"need clarification"| T3["ask_clarifying_question\nreturn early"]
    Tools -->|"web context"| T4["web_lookup\noptional, opt-in per tenant"]
    T1 & T2 & T4 --> Synth["Synthesize answer · DeepSeek V4 Flash"]
    Synth --> Check["Self-check · Gemini 3.5 Flash"]
    Check -->|"faithfulness ≥ 0.7"| Out["Return answer + citations"]
    Check -->|"< 0.7"| Retry["Retry with DeepSeek V4 Pro"]
    Retry --> Out
    T3 --> Out
```

The **faithfulness score** is returned with every answer and stored on `chat_messages.faithfulness`. The UI displays a color-coded badge (red/yellow/green).

## Webhook Contracts

### FastAPI → n8n: Ingest

```text
POST /webhook/ingest
```
```json
{
  "document_id": "uuid",
  "tenant_id": "uuid",
  "file_path": "/uploads/filename.pdf",
  "source_type": "pdf",
  "title": "Document title",
  "callback_token": "<N8N_CALLBACK_TOKEN>"
}
```

### FastAPI → n8n: Retrieve

```text
POST /webhook/retrieve
```
```json
{
  "query": "How do I reset the device?",
  "tenant_id": "uuid",
  "conversation_id": "uuid",
  "conversation_history": [],
  "max_chunks": 5,
  "include_ephemeral": true
}
```

### n8n → FastAPI: Ingestion Status Callback

```text
POST /webhooks/n8n/ingestion-status
```
```json
{
  "document_id": "uuid",
  "status": "completed",
  "chunk_count": 42,
  "error_message": null,
  "callback_token": "<N8N_CALLBACK_TOKEN>"
}
```

### Retrieve Response Shape

```json
{
  "answer": "To reset the device... [Manual, p.12]",
  "sources": [
    {
      "document_id": "uuid",
      "title": "Manual",
      "chunk_text": "...",
      "page_number": 12,
      "score": 0.94
    }
  ],
  "follow_up_questions": ["...", "...", "..."],
  "faithfulness": 0.92,
  "requires_clarification": false,
  "metadata": {
    "model": "deepseek-v4-flash",
    "retrieval_time_ms": 1100,
    "chunks_retrieved": 5
  }
}
```
