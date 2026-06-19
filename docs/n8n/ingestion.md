# Ingestion Pipeline

The ingestion pipeline runs as an n8n workflow that processes uploaded documents into queryable vector embeddings.

**Owner**: M5 · **Workflow**: `n8n-workflows/ingestion-pipeline.json`

## Pipeline Stages

```{mermaid}
flowchart LR
    Trigger["Webhook Trigger"] --> Switch["Switch by source_type"]
    Switch -->|PDF| PDF["Extract text (pypdf)"]
    Switch -->|DOCX| DOCX["Extract text (python-docx)"]
    Switch -->|TXT| TXT["Read raw text"]
    Switch -->|URL| URL["Scrape web page"]
    Switch -->|"Scanned PDF"| OCR["OCR via GPT-4o vision"]
    PDF & DOCX & TXT & URL & OCR --> Chunk["Chunk text\n512 tokens, 50 overlap"]
    Chunk --> Embed["Voyage embed\nvoyage-4-large (1024d)"]
    Embed --> Store["INSERT INTO document_chunks\n(tenant_id, document_id, embedding, text, page)"]
    Store --> Callback["POST /webhooks/n8n/ingestion-status"]
```

## Stage Details

### 1. Webhook Trigger

Receives the ingestion request from FastAPI:

```json
{
  "document_id": "uuid",
  "tenant_id": "uuid",
  "file_path": "/uploads/filename.pdf",
  "source_type": "pdf",
  "title": "Document title",
  "callback_token": "<shared secret>"
}
```

### 2. Text Extraction

| Source Type | Method |
|:-----------|:-------|
| PDF (text-based) | pypdf in Code node |
| PDF (scanned) | OpenAI GPT-4o vision API |
| DOCX | python-docx in Code node |
| TXT | Direct read |
| URL | HTTP Request node + HTML-to-text |

### 3. Chunking

- **Strategy**: Fixed-size with overlap
- **Chunk size**: 512 tokens
- **Overlap**: 50 tokens
- **Metadata preserved**: page number, position in document

### 4. Embedding

- **Model**: Voyage `voyage-4-large`
- **Dimensions**: 1024
- **API**: HTTP Request node to Voyage API
- **Batching**: Chunks are batched for efficiency

### 5. Storage

```sql
INSERT INTO document_chunks (
    id, tenant_id, document_id, chunk_index,
    chunk_text, page_number, embedding, created_at
) VALUES (...)
```

HNSW index parameters: `m=16, ef_construction=64`.

### 6. Callback

On success or failure, n8n calls back to FastAPI:

```text
POST /webhooks/n8n/ingestion-status
```
```json
{
  "document_id": "uuid",
  "status": "completed",
  "chunk_count": 42,
  "callback_token": "<shared secret>"
}
```

## Ephemeral Ingestion

The ephemeral pipeline (`ingest-ephemeral.json`) follows the same stages but writes to `ephemeral_chunks` with an `expires_at` timestamp (1 hour from now). These chunks are scoped to a single conversation and auto-purged by a cron job.
