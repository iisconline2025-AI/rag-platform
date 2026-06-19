# Team

## Members

| Member | Role | Track | Key Files |
|:-------|:-----|:------|:----------|
| **M1** | Tech Lead / Integration | Lead | Repo setup, CI/CD, deployment, integration |
| **M2** | Backend: Auth & Core | Backend | `app/api/auth.py`, `app/core/`, `app/schemas/auth.py` |
| **M3** | Backend: Document & Chat APIs | Backend | `app/api/admin.py`, `app/api/chat.py` |
| **M4** | Backend: Webhooks | Backend | `app/api/webhooks.py`, `app/bots/slack.py` |
| **M5** | n8n: Ingestion Pipeline | n8n | `n8n-workflows/ingestion-pipeline.json` |
| **M6** | n8n: Retrieval Pipeline | n8n | `n8n-workflows/retrieval-pipeline.json` |
| **M7** | Database & Infrastructure | Infra | `docker-compose.yml`, `database/init.sql`, CI |
| **M8** | Frontend: Admin Portal | Frontend | `frontend/src/app/admin/` |
| **M9** | Frontend: Chat Portal | Frontend | `frontend/src/app/chat/` |
| **M10** | Evaluation & Testing | QA | `evaluation/`, `tests/` |
| **M11** | Documentation & Demo | Docs | `docs/`, `README.md`, demo script |
| **M12** | WhatsApp Bot Specialist | Bot | `app/bots/whatsapp.py`, `app/bots/tenant_map.py` |
| **M13** | Customer Onboarding | Platform | `app/api/onboarding.py`, `frontend/src/app/onboarding/` |

## Organization

**IISc Bengaluru** · Department of Computational and Data Science · DA225o Deep Learning · 2026

## Tracks

- **Backend** (M2, M3, M4) — FastAPI gateway, auth, API endpoints
- **n8n** (M5, M6) — RAG ingestion and retrieval workflows
- **Infra** (M7) — Docker, CI/CD, database, deployment
- **Frontend** (M8, M9) — Next.js admin portal and chat UI
- **QA** (M10) — RAGAS evaluation, integration tests
- **Bot** (M12) — WhatsApp bot integration
- **Platform** (M13) — Tenant onboarding wizard
- **Docs** (M11) — Documentation, demo preparation
- **Lead** (M1) — Integration, PR reviews, architecture decisions
