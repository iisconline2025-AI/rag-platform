# ARCHITECTURE.md — IISc Grounded Agentic RAG Platform

## System Overview

```
                 ┌───────────────────────────────────────────────┐
                 │            FRONTEND  ·  Next.js 14             │
                 │  /admin (M8)  │  /chat (M9)  │  /onboarding (M13) │
                 └──────┬────────┴──────┬────────┴──────┬──────────┘
                        │ JWT token      │               │
                 ┌──────▼────────────────▼───────────────▼──────────┐
                 │          FASTAPI GATEWAY  ·  Python 3.11          │
                 │  /auth  /admin  /chat  /webhooks  /onboarding     │
                 │  JWT middleware · CORS · rate limiting · logging   │
                 └───────┬──────────────┬───────────────┬────────────┘
                         │              │               │
              ┌──────────▼──┐    ┌──────▼─────┐  ┌────▼──────────────┐
              │ PostgreSQL  │    │  Redis 7   │  │   n8n  (port 5678) │
              │ + pgvector  │    │  sessions  │  │   RAG Engine       │
              │  port 5432  │    │  port 6379 │  │   Ingestion WF     │
              └──────────┬──┘    └────────────┘  │   Retrieval WF     │
                         │                        └────────┬───────────┘
                         │                                 │
                         └─────── shared DB ───────────────┘
                                                           │
                                               ┌───────────▼──────────┐
                                               │    OpenAI  API        │
                                               │  /embeddings          │
                                               │  /chat/completions    │
                                               └──────────────────────┘

  External Channels:
  ┌──────────────┐     ┌─────────────┐
  │  WhatsApp    │     │  Slack Bot  │
  │  (Twilio)    │     │  Events API │
  └──────┬───────┘     └──────┬──────┘
         │ POST /webhooks      │ POST /webhooks
         └─────────────────────┘
               ↓ FastAPI webhooks.py
               ↓ calls n8n retrieval webhook
               ↓ returns answer → TwiML / Slack reply
```

## Component Descriptions

### FastAPI Gateway (backend/)
- **Responsibility**: Auth, routing, file storage, webhook receipt, DB CRUD
- **Does NOT**: embed text, call LLMs, chunk documents
- **Key files**: `app/main.py`, `app/api/`, `app/core/`, `app/models/`
- **Port**: 8000

### n8n RAG Engine (n8n-workflows/)
- **Responsibility**: All AI logic — parse, chunk, embed, store, retrieve, generate
- **Ingestion workflow**: Triggered by FastAPI via HTTP POST when file is uploaded
- **Retrieval workflow**: Triggered by FastAPI via HTTP POST when user sends a query
- **Port**: 5678 (n8n UI), webhook URL: `http://n8n:5678/webhook/...`

### PostgreSQL + pgvector (database/)
- **Tables**: `tenants`, `users`, `documents`, `document_chunks`, `conversations`, `chat_messages`
- **pgvector**: `document_chunks.embedding vector(1536)` — cosine similarity search
- **Tenant isolation**: every table has `tenant_id UUID` — ALL queries filter by it

### Redis (cache)
- JWT token blacklist
- Session cache
- Rate limiting counters

### Next.js Frontend (frontend/)
- **Admin portal** (`/admin`): login, upload docs, manage users, tenant settings
- **Chat portal** (`/chat`): query knowledge base, view citations, conversation history
- **Onboarding wizard** (`/onboarding`): new tenant registration flow

## Data Flow — Document Ingestion

```
User (admin) uploads PDF via Admin UI
  → POST /admin/documents/upload (FastAPI, M3)
  → File saved to /uploads volume
  → FastAPI POSTs to n8n ingestion webhook with {file_path, tenant_id, document_id}
  → n8n Ingestion Workflow (M5):
      1. Read file (pypdf / python-docx / requests)
      2. Extract text
      3. Chunk text (512 tokens, 50-token overlap)
      4. For each chunk: POST /embeddings → OpenAI → get vector
      5. INSERT INTO document_chunks (tenant_id, document_id, content, embedding, ...)
      6. POST /webhooks/n8n/ingestion-status → FastAPI (status: completed)
  → FastAPI updates documents.status = "completed"
  → Admin UI shows ✅ green badge
```

## Data Flow — User Query

```
User types question in Chat UI
  → POST /chat/query {query, conversation_id, tenant_id} (FastAPI, M3)
  → FastAPI POSTs to n8n retrieval webhook
  → n8n Retrieval Workflow (M6):
      1. POST /embeddings → OpenAI → embed the query
      2. SELECT ... FROM document_chunks WHERE tenant_id=X
         ORDER BY embedding <=> $query_vec LIMIT 5
      3. Assemble context: top-5 chunks + conversation history
      4. POST /chat/completions → OpenAI GPT with system prompt + context
      5. Extract answer + map citations to source chunks
      6. Generate 3 follow-up questions
      7. Return N8nRetrieveResponse
  → FastAPI saves messages to chat_messages table
  → Chat UI renders answer + collapsible citations + follow-up chips
```

## Data Flow — WhatsApp Query

```
User sends WhatsApp message
  → Twilio POSTs to POST /webhooks/whatsapp (FastAPI, M4)
  → FastAPI validates Twilio signature
  → Lookup phone_number → tenant_id (tenant_map table, M12)
  → FastAPI calls n8n retrieval webhook (same as web chat)
  → Returns answer → FastAPI responds with TwiML
  → Twilio delivers reply to user's WhatsApp
```

## Database Schema

```sql
-- Tenants (each customer company)
CREATE TABLE tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  plan VARCHAR(50) DEFAULT 'free',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  email VARCHAR(255) UNIQUE NOT NULL,
  hashed_password VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'user',   -- 'super_admin' | 'admin' | 'user'
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Documents uploaded by admins
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  uploaded_by UUID REFERENCES users(id),
  title VARCHAR(500) NOT NULL,
  source_type VARCHAR(50) NOT NULL,   -- 'pdf' | 'docx' | 'txt' | 'url'
  source_url TEXT,
  file_path TEXT,
  status VARCHAR(50) DEFAULT 'pending',   -- 'pending'|'processing'|'completed'|'failed'
  chunk_count INTEGER DEFAULT 0,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vector chunks (the RAG store)
CREATE TABLE document_chunks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  embedding vector(1536),             -- pgvector — text-embedding-3-small
  chunk_index INTEGER NOT NULL,
  page_number INTEGER,
  token_count INTEGER,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX ON document_chunks USING hnsw (embedding vector_cosine_ops);
CREATE INDEX ON document_chunks (tenant_id);

-- Conversations
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  title VARCHAR(500),
  channel VARCHAR(50) DEFAULT 'web',   -- 'web' | 'whatsapp' | 'slack'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chat messages
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL,   -- 'user' | 'assistant'
  content TEXT NOT NULL,
  sources JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- WhatsApp phone → tenant mapping
CREATE TABLE whatsapp_tenant_map (
  phone_number VARCHAR(20) PRIMARY KEY,
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## n8n Webhook Contracts

### Ingestion Webhook
```json
POST http://n8n:5678/webhook/ingest
{
  "document_id": "uuid",
  "tenant_id": "uuid",
  "file_path": "/uploads/filename.pdf",
  "source_type": "pdf",
  "title": "Document title"
}
```

### Retrieval Webhook
```json
POST http://n8n:5678/webhook/retrieve
{
  "query": "How do I reset the device?",
  "tenant_id": "uuid",
  "conversation_history": [
    {"role": "user", "content": "..."},
    {"role": "assistant", "content": "..."}
  ],
  "max_chunks": 5
}
```
Response:
```json
{
  "answer": "To reset the device...",
  "sources": [
    {"document_id": "uuid", "title": "Manual", "chunk_text": "...", "page_number": 12, "score": 0.94}
  ],
  "follow_up_questions": ["What if reset fails?", "Where is the reset button?"],
  "metadata": {"model": "gpt-4o-mini", "retrieval_time_ms": 1200, "chunks_retrieved": 5}
}
```

## Security Considerations
- JWT tokens expire in 24h; refresh tokens in Redis (blacklist on logout)
- All DB queries include `WHERE tenant_id = :tenant_id` — enforced by `get_current_tenant()` dependency
- Twilio webhook signature validated with `TWILIO_AUTH_TOKEN`
- Slack request verified with HMAC-SHA256
- File uploads: validate MIME type, max 50MB, store outside web root
- OpenAI API key never sent to frontend
