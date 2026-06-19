# Quick Start Guide

## Prerequisites

- **Docker & Docker Compose** — for PostgreSQL + pgvector and n8n
- **Python 3.11+** — for the FastAPI backend
- **Node.js 18+** — for the Next.js frontend

## Local Development Setup

### 1. Clone and Configure

```bash
git clone https://github.com/iisconline2025-AI/rag-platform.git
cd rag-platform
cp .env.example .env
```

Edit `.env` and fill in your API keys. See [Deployment Guide](deployment.md) for how to obtain each key.

### 2. Start Infrastructure

```bash
docker compose up -d
```

This starts:
- **PostgreSQL 17 + pgvector** on port 5432
- **n8n** on port 5678

### 3. Backend Setup

```bash
cd backend
pip install -r requirements.txt
alembic upgrade head              # apply database migrations
python -m app.scripts.seed_admin  # seed demo tenant + admin user
uvicorn app.main:app --reload --port 8000
```

### 4. Frontend Setup (separate terminal)

```bash
cd frontend
npm install
npm run dev
```

## Verify Installation

| Service | URL | Expected |
|:--------|:----|:---------|
| API docs (Swagger) | http://localhost:8000/docs | Interactive API documentation |
| Health check | http://localhost:8000/health | `{"status": "ok", "database": "connected"}` |
| n8n workflows | http://localhost:5678 | n8n editor UI |
| Frontend | http://localhost:3000 | Next.js application |

## Default Credentials

After running the seed script:

- **Email**: `admin@iisc-demo.com`
- **Password**: `changeme`

:::{warning}
Change the default password immediately in production deployments.
:::

## Import n8n Workflows

1. Open http://localhost:5678
2. Go to **Workflows → Import from File**
3. Import the three JSON files from `n8n-workflows/`:
   - `ingestion-pipeline.json`
   - `retrieval-pipeline.json`
   - `ingest-ephemeral.json`
4. Activate each workflow

## Mock Mode

Set `MOCK_N8N=true` in your `.env` to develop frontend/bot features without a running n8n instance. The `/chat/query` endpoint will return canned responses with realistic shape.

## Deployed Instances

| Service | URL |
|:--------|:----|
| Backend API | https://rag-platform-production.up.railway.app/docs |
| n8n | https://n8n-production-c637.up.railway.app/ |

## Next Steps

- Read the [Architecture](../architecture/system-design.md) to understand data flows
- Review the [API Reference](../development/api-reference.md) for endpoint details
- Check [Contributing](../development/contributing.md) for PR workflow
