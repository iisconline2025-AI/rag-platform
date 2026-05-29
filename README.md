# IISc Grounded Agentic RAG Platform

> Multi-tenant customer onboarding RAG platform — upload any documents, query via Web UI, WhatsApp, or Slack. Every answer is grounded and cited.

[![13 Members](https://img.shields.io/badge/team-13%20members-blue)]()
[![Sprint](https://img.shields.io/badge/sprint-29%20May%20–%203%20Jun%202026-green)]()
[![FastAPI](https://img.shields.io/badge/FastAPI-0.111-009688)]()
[![Next.js](https://img.shields.io/badge/Next.js-14-black)]()
[![n8n](https://img.shields.io/badge/n8n-RAG%20Engine-orange)]()

## Quick Start

```bash
git clone <repo-url> && cd rag-platform
cp .env.example .env        # fill in OPENAI_API_KEY, POSTGRES_PASSWORD, etc.
docker compose up -d        # starts postgres+pgvector, redis, n8n
cd backend && pip install -r requirements.txt
alembic upgrade head        # creates all tables
python -m app.scripts.seed_admin   # creates admin@example.com / changeme
uvicorn app.main:app --reload --port 8000
# frontend: cd frontend && npm install && npm run dev
```

Open:
- API docs: http://localhost:8000/docs
- n8n: http://localhost:5678 (import workflows from n8n-workflows/)
- Frontend: http://localhost:3000

## Architecture

```
Next.js → FastAPI Gateway → n8n RAG Engine → PostgreSQL/pgvector → OpenAI
                    ↑ WhatsApp (Twilio) + Slack (Events API)
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for full diagrams and data flows.

## Team
| Member | Role |
|---|---|
| M1 | Tech Lead / Integration |
| M2 | Backend: Auth & Core |
| M3 | Backend: Document & Chat APIs |
| M4 | Backend: Webhooks (WhatsApp + Slack) |
| M5 | n8n: Ingestion Pipeline |
| M6 | n8n: Retrieval + Generation Pipeline |
| M7 | Database & Infrastructure |
| M8 | Frontend: Admin Portal |
| M9 | Frontend: Chat Portal |
| M10 | Evaluation & Testing |
| M11 | Documentation & Demo |
| M12 | WhatsApp Bot Specialist |
| M13 | Customer Onboarding Platform |

## Documentation
- [CLAUDE.md](CLAUDE.md) — AI assistant instructions + project overview
- [PROJECT_SPEC.md](PROJECT_SPEC.md) — Goals, scope, success criteria
- [ARCHITECTURE.md](ARCHITECTURE.md) — System design, data flows, DB schema
- [SKILLS.md](SKILLS.md) — Platform capabilities reference
- [TEAM_WORKFLOW.md](TEAM_WORKFLOW.md) — PR rules, standup, branching
- [specs/openapi.yaml](specs/openapi.yaml) — Full API contract
- [specs/MODULE_SPEC_M*.md](specs/) — Per-member module specs
