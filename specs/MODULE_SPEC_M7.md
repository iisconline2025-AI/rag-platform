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
