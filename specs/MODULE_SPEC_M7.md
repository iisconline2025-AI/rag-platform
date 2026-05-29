# MODULE_SPEC_M7 — Database & Infrastructure

**Owner**: Member 7 | **Track**: Infra | **Branch**: `feat/infra`
**⚠️ P0 Day 1** — Push docker-compose skeleton by end of Day 1.

## Role
PostgreSQL + pgvector, Docker, docker-compose, Alembic setup, Redis, health checks.

## Day-by-Day Deliverables
| Day | Deliverable | Done? |
|---|---|---|
| 1 | `docker-compose.yml` skeleton (postgres, redis, n8n) — everyone needs this | ☐ |
| 2 | `database/init.sql` — pgvector extension + document_chunks table + HNSW index | ☐ |
| 2 | `backend/Dockerfile` + `frontend/Dockerfile` | ☐ |
| 2 | Full `docker-compose.yml` with backend + frontend + shared upload volume | ☐ |
| 3 | Alembic configuration — works with M2's migration | ☐ |
| 3 | Redis configuration for session/cache | ☐ |
| 3 | Full stack `docker compose up` — all services healthy | ☐ |
| 4 | Docker networking, environment variable management | ☐ |
| 5 | Health check endpoints in `GET /health` working | ☐ |
| 6 | Production docker-compose with resource limits + restart policies | ☐ |

## Files Owned
- `docker-compose.yml`
- `database/init.sql`
- `backend/Dockerfile`
- `frontend/Dockerfile`

## docker-compose.yml (complete)
```yaml
version: '3.9'
services:
  postgres:
    image: pgvector/pgvector:pg15
    environment:
      POSTGRES_DB: ragplatform
      POSTGRES_USER: raguser
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U raguser -d ragplatform"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s

  n8n:
    image: n8nio/n8n:latest
    environment:
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_DATABASE: n8n
      DB_POSTGRESDB_USER: raguser
      DB_POSTGRESDB_PASSWORD: ${POSTGRES_PASSWORD}
      N8N_BASIC_AUTH_ACTIVE: "true"
      N8N_BASIC_AUTH_USER: admin
      N8N_BASIC_AUTH_PASSWORD: ${N8N_BASIC_AUTH_PASSWORD:-n8nadmin}
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy

  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql+asyncpg://raguser:${POSTGRES_PASSWORD}@postgres:5432/ragplatform
      REDIS_URL: redis://redis:6379/0
      N8N_INGEST_WEBHOOK_URL: http://n8n:5678/webhook/ingest
      N8N_RETRIEVE_WEBHOOK_URL: http://n8n:5678/webhook/retrieve
    volumes:
      - ./uploads:/uploads
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:8000
    depends_on:
      - backend

volumes:
  postgres_data:
  n8n_data:
```

## database/init.sql
```sql
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- Tables are created by Alembic (M2).
-- This file only bootstraps the extension.
-- pgvector HNSW index is created via Alembic migration.
```

## Acceptance Criteria
- [ ] `docker compose up -d` starts all 5 services without errors
- [ ] `docker compose ps` shows all services healthy
- [ ] `psql -U raguser -d ragplatform -c "SELECT * FROM pg_extension WHERE extname='vector'"` returns 1 row
- [ ] `redis-cli ping` returns PONG
- [ ] n8n UI accessible at http://localhost:5678
- [ ] Shared `/uploads` volume accessible from both backend and n8n
