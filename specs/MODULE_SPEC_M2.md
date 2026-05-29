# MODULE_SPEC_M2 — Backend: Auth & Core

**Owner**: Member 2 | **Track**: Backend | **Branch**: `feat/auth`

## Role
FastAPI application scaffold, authentication system, SQLAlchemy models, Alembic migrations, JWT middleware, seed script.

## Day-by-Day Deliverables
| Day | Deliverable | Done? |
|---|---|---|
| 1 | Read `specs/openapi.yaml`. Set up local FastAPI env. Create branch. | ☐ |
| 2 | `backend/app/main.py` — FastAPI app, CORS, middleware, error handlers | ☐ |
| 2 | `backend/alembic/` — init Alembic, create initial migration with all models | ☐ |
| 3 | `backend/scripts/seed_admin.py` — auto-create demo tenant + admin user | ☐ |
| 4 | Auth integration test: full login → JWT → protected route flow works end-to-end | ☐ |
| 5 | Unit tests for auth flows (login, register, me, logout, token expiry) | ☐ |
| 6 | Bug fixes, security hardening | ☐ |

## Files Owned
- `backend/app/main.py`
- `backend/alembic/`
- `backend/app/core/config.py`
- `backend/app/core/security.py`
- `backend/app/core/dependencies.py`
- `backend/scripts/seed_admin.py`

## main.py Requirements
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import auth, admin, chat, webhooks, onboarding

app = FastAPI(title="IISc RAG Platform", version="1.0.0")
app.add_middleware(CORSMiddleware, ...)
app.include_router(auth.router, prefix="/auth", tags=["Auth"])
app.include_router(admin.router, prefix="/admin", tags=["Admin"])
app.include_router(chat.router, prefix="/chat", tags=["Chat"])
app.include_router(webhooks.router, prefix="/webhooks", tags=["Webhooks"])
app.include_router(onboarding.router, prefix="/onboarding", tags=["Onboarding"])

@app.get("/health")
async def health_check(): ...
```

## Alembic Migration Requirements
- Must create ALL tables from `ARCHITECTURE.md` DB schema
- Migration runs with `alembic upgrade head`
- Idempotent — safe to run multiple times

## Seed Script Requirements
```bash
python -m app.scripts.seed_admin
# Creates:
#   Tenant: name="IISc Demo", slug="iisc-demo"
#   User: email=SEED_ADMIN_EMAIL, role="super_admin"
# Reads from .env: SEED_ADMIN_EMAIL, SEED_ADMIN_PASSWORD, SEED_TENANT_NAME
```

## JWT Middleware
- Every protected route calls `get_current_user()` dependency
- Extracts Bearer token from Authorization header
- Validates with SECRET_KEY + ALGORITHM from config
- Returns `UserOut` object injected into route handler

## Acceptance Criteria
- [ ] `uvicorn app.main:app --reload` starts without errors
- [ ] `alembic upgrade head` creates all tables in postgres
- [ ] `python -m app.scripts.seed_admin` creates admin user
- [ ] `POST /auth/login` returns JWT
- [ ] `GET /auth/me` returns user with valid JWT, 401 without
- [ ] Unit tests pass: `pytest tests/test_auth.py`
