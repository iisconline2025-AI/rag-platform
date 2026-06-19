# System Design

## High-Level Architecture

```{mermaid}
flowchart LR
    subgraph Clients
        Web["Web UI · Next.js 14"]
        WA["WhatsApp · Twilio"]
        MCP["MCP Clients · Claude/Cursor"]
    end

    subgraph Gateway["FastAPI Gateway · Railway"]
        API["Auth · Upload · Routing"]
        MCPSrv["/mcp/* JSON-RPC"]
    end

    subgraph RAG["n8n RAG Engine · Railway"]
        Ingest["Ingestion Pipeline"]
        Retrieve["Agentic Retrieval"]
        Ephemeral["Ephemeral Ingest"]
    end

    subgraph DB["Neon Postgres + pgvector"]
        DocChunks[("document_chunks · vector(1024)")]
        EphChunks[("ephemeral_chunks · TTL=1h")]
        Meta[("tenants · users · conversations")]
    end

    subgraph AI["AI Providers"]
        Voyage["Voyage · embed + rerank"]
        DS["DeepSeek V4 · generation"]
        Gemini["Gemini 3.5 · self-check"]
        OAI["OpenAI gpt-4o · OCR"]
    end

    Web & WA & MCP --> API
    MCP --> MCPSrv --> API
    API --> Ingest & Retrieve & Ephemeral
    Ingest --> Voyage --> DocChunks
    Ingest --> OAI
    Ephemeral --> Voyage --> EphChunks
    Retrieve --> Voyage & DocChunks & EphChunks & DS & Gemini
    API --> Meta
```

## Design Principles

### FastAPI is a Thin Gateway
- **Does**: JWT auth, file upload validation, webhook receipt, DB CRUD, MCP server, rate-limit
- **Does NOT**: call LLMs, embed text, chunk documents

All AI logic (embed, retrieve, rerank, generate, self-check) lives inside n8n workflows.

### n8n is the RAG Engine
- **Ingestion pipeline**: parse → OCR → chunk → embed → store
- **Agentic retrieval**: AI Agent node with 4 tools → rerank → synthesize → self-check
- **Ephemeral ingest**: same as ingestion but writes to ephemeral_chunks with TTL

### No Redis
JWT is stateless (24h expiry). Rate-limiting uses in-process slowapi. No session store needed.

## Component Map

| Component | Technology | Key Files |
|:----------|:-----------|:----------|
| API Gateway | FastAPI | `backend/app/main.py`, `backend/app/api/` |
| Auth | JWT + bcrypt | `backend/app/core/security.py`, `backend/app/core/dependencies.py` |
| Database | SQLAlchemy async + Alembic | `backend/app/core/database.py`, `backend/app/models/` |
| File Validation | Magic bytes + MIME | `backend/app/services/file_validator.py` |
| n8n Client | httpx | `backend/app/services/n8n_client.py` |
| MCP Server | JSON-RPC | `backend/app/mcp/server.py`, `backend/app/mcp/tools.py` |
| Vector DB | pgvector (1024-dim, HNSW) | `database/init.sql` |

## Hosting Targets

| Layer | Provider | Cost |
|:------|:---------|:-----|
| Frontend | Vercel (Hobby) | Free |
| Backend + n8n | Railway | ~$5/mo |
| Postgres + pgvector | Neon | Free (10 GB) |
| Embeddings + Rerank | Voyage | Free (200M tokens) |
| Generation | DeepSeek V4 Flash | ~$0 (pay-as-you-go) |
| Self-check | Gemini 3.5 Flash | Free tier |
| Vision OCR | OpenAI | $5 prepaid |
| **Total** | | **~$10 one-time + ~$5/mo** |
