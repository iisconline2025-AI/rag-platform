# MODULE_SPEC_M7 — Database & Infrastructure

**Owner**: Member 7 | **Track**: Infra | **Branch**: `feat/infra`
**⚠️ P0 Day 1** — Push docker-compose skeleton by end of Day 1.

> **Update (locked):** Redis is removed. Stateless JWT + in-process `slowapi`
> for rate-limiting. Production deploys to **Neon Postgres + pgvector**
> (database) + **Railway** (backend + n8n) + **Vercel** (frontend). Local dev
> still uses `docker compose` (postgres + n8n only).

## Role
PostgreSQL + pgvector (Neon in prod, docker locally), n8n container, Dockerfiles, Alembic setup, health checks, hourly cleanup cron for ephemeral chunks.

## Day-by-Day Deliverables
| Day | Deliverable | Done? |
|---|---|---|
| 1 | `docker-compose.yml` skeleton (postgres + n8n + backend + frontend, **no redis**) | ☑ (M1) |
| 1 | `database/init.sql` — pgvector + schema + `ephemeral_chunks` + HNSW + cleanup fn | ☑ (M1) |
| 2 | `backend/Dockerfile` + `frontend/Dockerfile` | ☐ |
| 3 | Alembic configuration — generate initial migration matching `init.sql` | ☐ |
| 3 | Full stack `docker compose up` — all services healthy | ☐ |
| 4 | Hourly cron for `scripts/cleanup_ephemeral.py` (local: systemd-timer or APScheduler; prod: Railway cron) | ☐ |
| 5 | `GET /health` returns real status for db + n8n (no redis ping) | ☐ |
| 6 | Neon production database provisioned, `init.sql` run | ☐ |
| 7 | Railway deploy of backend + n8n (see `docs/DEPLOYMENT.md`) | ☐ |

## Files Owned
- `docker-compose.yml`
- `database/init.sql`
- `backend/Dockerfile`
- `frontend/Dockerfile`
- `backend/scripts/cleanup_ephemeral.py` (cron job runner)

## Acceptance Criteria
- [ ] `docker compose up -d` starts postgres + n8n + backend + frontend without errors
- [ ] `docker compose ps` shows all services healthy
- [ ] `psql -U raguser -d ragplatform -c "SELECT * FROM pg_extension WHERE extname='vector'"` returns 1 row
- [ ] `SELECT cleanup_expired_ephemeral_chunks()` returns an integer
- [ ] n8n UI accessible at http://localhost:5678
- [ ] Shared `/uploads` volume accessible from both backend and n8n
- [ ] `python -m scripts.cleanup_ephemeral` runs without error
- [ ] See `docs/DEPLOYMENT.md` for production Neon + Railway + Vercel steps


---
<!-- AUTO-APPENDED:SKILLS-V1 -->
## Skills Required
- **Must-have:** Docker + docker-compose, PostgreSQL, pgvector extension, Neon (serverless Postgres), Railway (PaaS) or Render, secret/env management, cron scheduling.
- **Nice-to-have:** Bash, GitHub Actions, observability (Grafana, Sentry).
- **⚠ CRITICAL PATH:** Your Day-1 output unblocks M2, M5, M6. Treat as P0.

## Detailed Step-by-Step Plan
### Day 1 — Neon DB (1-2 hours, P0)
1. Sign up at https://console.neon.tech (free tier: 10 GB).
2. Create project `rag-platform`, region `aws-ap-south-1` (Mumbai).
3. In SQL Editor run: `CREATE EXTENSION IF NOT EXISTS vector;` then paste full `database/init.sql` content. Verify all tables + HNSW indexes created.
4. Copy connection string (pooled): `postgres://user:pass@ep-xxx.neon.tech/neondb?sslmode=require`.
5. Post in #infra Slack channel: `DATABASE_URL=...` (use a secret share, not plaintext).

### Day 1 (cont.) — n8n on Railway (2 hours)
6. Sign up at https://railway.app. New project → Deploy from template → "n8n".
7. Set env vars: `N8N_BASIC_AUTH_ACTIVE=true`, `N8N_BASIC_AUTH_USER`, `N8N_BASIC_AUTH_PASSWORD`, `DB_TYPE=postgresdb`, `DB_POSTGRESDB_HOST/PORT/USER/PASSWORD/DATABASE` pointing to a SEPARATE Neon branch `n8n`.
8. Generate public URL; share with M5 + M6.

### Day 2 — Backend on Railway
9. New service → Deploy from GitHub repo → root `backend/`. Auto-detects Dockerfile.
10. Set all env vars from `.env` (DATABASE_URL, VOYAGE_API_KEY, DEEPSEEK_API_KEY, GEMINI_API_KEY, OPENAI_API_KEY, TWILIO_*, JWT_SECRET, N8N_*_WEBHOOK_URL, MOCK_N8N=true initially).
11. Add `railway.json` with start command `alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port `.
12. Verify `/health` returns 200.

### Day 3 — Frontend on Vercel
13. `cd frontend && vercel --prod` (link to GitHub repo).
14. Set `NEXT_PUBLIC_API_BASE_URL` to Railway backend URL.

### Day 4 — Cron + Backups
15. Add Railway Cron service: command `python -m scripts.cleanup_ephemeral`, schedule `0 * * * *` (hourly).
16. Enable Neon point-in-time-restore (default 7 days).

### Day 5 — Monitoring
17. Wire Sentry (free tier) DSN into backend `app/main.py`.
18. Set up uptime check on `/health` via UptimeRobot.

### Day 6 — Cutover Day
19. Coordinate with M1: set `MOCK_N8N=false` on Railway, restart service, run smoke test.

## Learning Resources
- Neon docs: https://neon.tech/docs
- Railway docs: https://docs.railway.app
- pgvector: https://github.com/pgvector/pgvector
- Vercel Next.js: https://vercel.com/docs/frameworks/nextjs
