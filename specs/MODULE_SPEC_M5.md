# MODULE_SPEC_M5 — n8n: Ingestion Pipeline

**Owner**: Member 5 | **Track**: n8n | **Branch**: `feat/n8n-ingest`
**⚠️ CRITICAL PATH** — Must be complete by end of Day 3.

## Role
Build the document ingestion n8n workflow: webhook trigger → parse → chunk → embed → pgvector store → callback.

## Day-by-Day Deliverables
| Day | Deliverable | Done? |
|---|---|---|
| 1 | Set up n8n Docker (use M7's docker-compose). Create blank ingestion workflow. | ☐ |
| 2 | Webhook trigger node + Switch node (PDF/DOCX/TXT/URL) + PDF extract (Code node + pypdf) | ☐ |
| 2 | DOCX extract + TXT read + URL scrape (HTTP Request node) | ☐ |
| 3 | Chunking Code node (512 tokens, 50 overlap) | ☐ |
| 3 | OpenAI `/embeddings` HTTP Request node | ☐ |
| 3 | Loop + Postgres INSERT document_chunks node | ☐ |
| 3 | Callback HTTP Request → `POST /webhooks/n8n/ingestion-status` | ☐ |
| 4 | Error handling — catch failures, callback with status=failed | ☐ |
| 5 | Test with real PDFs (5–10 documents from M10's sample set) | ☐ |
| 6 | Export workflow JSON + document setup steps | ☐ |

## Files Owned
- `n8n-workflows/ingestion-pipeline.json`

## Workflow Architecture
```
[Webhook Trigger]  ← POST /webhook/ingest
  {document_id, tenant_id, file_path, source_type, title}
        │
        ▼
[Switch: source_type]
  pdf   → [Code: pypdf extract]
  docx  → [Code: python-docx extract]
  txt   → [Read Binary File]
  url   → [HTTP Request] → [HTML Extract]
        │
        ▼
[Code: Chunk Text]
  // Split into 512-token chunks with 50-token overlap
  // Add metadata: chunk_index, page_number (if PDF)
        │
        ▼
[Loop Over Chunks]
  │
  ├── [HTTP Request: OpenAI /embeddings]
  │     POST https://api.openai.com/v1/embeddings
  │     {input: chunk_text, model: "text-embedding-3-small"}
  │
  └── [Postgres: INSERT document_chunks]
        INSERT INTO document_chunks
          (tenant_id, document_id, content, embedding, chunk_index, page_number, token_count)
        VALUES ($1, $2, $3, $4::vector, $5, $6, $7)
        │
        ▼
[HTTP Request: Callback]
  POST http://backend:8000/webhooks/n8n/ingestion-status
  {document_id, status: "completed", chunk_count: N}
```

## Chunking Code Node
```javascript
// Input: items[0].json.text (full extracted text)
// Output: array of chunk objects
const text = items[0].json.text;
const CHUNK_SIZE = 512;  // tokens ≈ characters/4
const OVERLAP = 50;
const words = text.split(' ');
const chunks = [];
let i = 0;
while (i < words.length) {
  const chunk = words.slice(i, i + CHUNK_SIZE).join(' ');
  chunks.push({ content: chunk, chunk_index: chunks.length });
  i += CHUNK_SIZE - OVERLAP;
}
return chunks.map(c => ({ json: c }));
```

## n8n Credentials Needed
- `OpenAI API`: OPENAI_API_KEY
- `Postgres`: host=postgres, port=5432, db=ragplatform, user=raguser, password from env
- Enable pgvector in Postgres node (custom SQL mode)

## Acceptance Criteria
- [ ] PDF upload → chunks stored in `document_chunks` table with embeddings
- [ ] URL → text scraped → chunked → embedded → stored
- [ ] Callback received by FastAPI: document status = "completed"
- [ ] Error path: bad file → callback with status="failed", error_message
- [ ] Test with 3 different PDF types (short, long, multi-page)
- [ ] Export `n8n-workflows/ingestion-pipeline.json` committed to repo

---

## ?? Locked Scope Update (M1 / 29-May)

**Embeddings**: Voyage `voyage-4-large` (1024 dims). The pgvector column is `vector(1024)` � see `database/init.sql`.

**Multimodal / OCR**: If a PDF has no extractable text (scanned image), call **OpenAI gpt-4o vision** from the `Extract + OCR` node to OCR each page. Mark `metadata.used_ocr = true` so we can audit cost.

**Two ingestion workflows**:
1. [`ingestion-pipeline.json`](../n8n-workflows/ingestion-pipeline.json) � admin uploads ? `document_chunks` (forever, tenant-wide)
2. [`ingest-ephemeral.json`](../n8n-workflows/ingest-ephemeral.json) � WhatsApp/chat uploads ? `ephemeral_chunks` (1-hour TTL, conversation-scoped). Hourly cron purges via `cleanup_expired_ephemeral_chunks()`.

**Callback contract** (n8n ? FastAPI):
```json
POST /webhooks/n8n/ingestion-status
{ "document_id": "uuid", "status": "completed", "chunk_count": 42, "callback_token": "<N8N_CALLBACK_TOKEN>" }
```
