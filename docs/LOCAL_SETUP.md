# Local Setup Guide

**Owner:** M7 (Infra/DevOps)
**Audience:** All 13 module developers
**Time to first request:** ~10 min on a fresh machine

---

## Prerequisites

| Tool | Version | Check |
|---|---|---|
| Docker Desktop | ≥ 24.x | `docker --version` |
| Python | 3.11.x | `python --version` |
| Node.js | 18 or 20 LTS | `node --version` |
| Git | any recent | `git --version` |

> Windows users: use PowerShell, not cmd.exe.

---

## 1. Clone & configure

```powershell
git clone https://github.com/iisconline2025-AI/rag-platform.git
cd rag-platform
git checkout dev
cp .env.example .env
```

Fill in `.env` from **Zoho Vault → folder `rag-platform`**:

| Var | Source |
|---|---|
| `DATABASE_URL` | Neon → Connection Details → Pooled |
| `JWT_SECRET` | Vault → `RAG_JWT_SECRET` |
| `N8N_CALLBACK_TOKEN` | Vault → `RAG_N8N_CALLBACK_TOKEN` |
| `MCP_API_KEY` | Vault → `RAG_MCP_API_KEY` |
| `SEED_ADMIN_EMAIL` | `admin@iisc-demo.in` |
| `SEED_ADMIN_PASSWORD` | Vault → `RAG_SEED_ADMIN` |
| `VOYAGE_API_KEY` | Vault → `RAG_VOYAGE_KEY` |
| `DEEPSEEK_API_KEY` | Vault → `RAG_DEEPSEEK_KEY` |
| `GEMINI_API_KEY` | Vault → `RAG_GEMINI_KEY` |
| `OPENAI_API_KEY` | Vault → `RAG_OPENAI_KEY` |
| `TWILIO_ACCOUNT_SID` | Vault → `RAG_TWILIO_SID` |
| `TWILIO_AUTH_TOKEN` | Vault → `RAG_TWILIO_TOKEN` |
| `MOCK_N8N` | `true` (until n8n workflows are wired) |

---

## 2. Option A — Everything in Docker (recommended for non-backend devs)

```powershell
docker compose up -d
```

Wait ~60 sec. Services come up in order: postgres → n8n → backend → frontend.

Check status:
```powershell
docker compose ps
```

URLs:
- Frontend: http://localhost:3000
- Backend API + Swagger: http://localhost:8000/docs
- n8n UI: http://localhost:5678 (login: `admin` / value of `N8N_BASIC_AUTH_PASSWORD`)
- Postgres: localhost:5432 (user `raguser` / `POSTGRES_PASSWORD`)

Tail logs:
```powershell
docker compose logs -f backend
```

Stop everything:
```powershell
docker compose down            # keeps data
docker compose down -v         # WIPES postgres volume — careful
```

---

## 2. Option B — Backend in native Python (faster iteration for M2/M3/M4)

Keep postgres + n8n in Docker; run FastAPI on host:

```powershell
docker compose up -d postgres n8n

cd backend
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt

# First-time only: seed super-admin
python -m scripts.seed_admin

uvicorn app.main:app --reload --port 8000
```

Hot reload on file save. Logs print to terminal.

---

## 3. Frontend native dev (for M8/M9)

```powershell
cd frontend
npm install
npm run dev        # http://localhost:3000
```

Set `NEXT_PUBLIC_API_URL=http://localhost:8000` in `frontend/.env.local`.

---

## 4. Use the deployed cloud backend instead of local

If you only want to develop frontend/bots and not run backend yourself:

```env
# frontend/.env.local
NEXT_PUBLIC_API_URL=https://rag-platform-production.up.railway.app
```

No local Docker needed.

---

## 5. Verify everything is healthy

```powershell
# 1. DB has tables
docker compose exec postgres psql -U raguser -d ragplatform -c "\dt"
# Expect 9 tables

# 2. Backend responds
curl http://localhost:8000/
# {"message":"IISc RAG Platform API","docs":"/docs"}

# 3. n8n UI loads
start http://localhost:5678
```

---

## 6. Common issues

| Symptom | Fix |
|---|---|
| `postgres: connection refused` | Wait 10 sec on first boot — health check finishes |
| `pip install` fails on `psycopg2-binary` | `pip install --upgrade pip setuptools wheel` then retry |
| Frontend `npm ci` fails | Delete `node_modules` + `package-lock.json`, run `npm install` |
| n8n shows blank page | First-boot can take 30 sec; refresh |
| `MOCK_N8N` still returning fake data | Set to `false` in `.env` and restart backend |
| Port 5432/3000/8000/5678 already in use | `docker compose down`, or change host port mapping in `docker-compose.yml` |

---

## 7. Cloud URLs (production)

| Service | URL | Owner |
|---|---|---|
| Backend API | https://rag-platform-production.up.railway.app | M7 |
| Backend Swagger | https://rag-platform-production.up.railway.app/docs | M7 |
| n8n | *(TBD — see Vault `RAG_N8N_URL`)* | M7 |
| Frontend | *(TBD after Vercel deploy)* | M8/M9 |
| Database | *(Neon, internal — see Vault `RAG_NEON_DATABASE_URL`)* | M7 |

---

## 8. Help

- Architecture questions → see `ARCHITECTURE.md`
- Module-specific rules → `.github/instructions/M<your-number>.instructions.md`
- Spec → `specs/MODULE_SPEC_M<your-number>.md`
- Infra issues → ping M7 in team group

**Last updated:** 30-May-2026 by M7
