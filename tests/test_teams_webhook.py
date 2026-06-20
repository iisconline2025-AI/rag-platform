"""M14 Teams webhook tests.

Hit the real FastAPI app over ASGI against a live Postgres (same pattern as
test_m4_slack.py). The Bot Framework JWT check is monkeypatched (no live JWKS
fetch). End-to-end tests that touch teams_workspace_map / processed_requests are
skipped if migration 0004 hasn't been applied.

    docker compose run --rm -v "$PWD":/repo -w /repo backend pytest tests/test_teams_webhook.py -v

NOTE: tests/ is M10-owned — this file is additive; coordinate sign-off with M10.
"""
import json
import os
import sys
import uuid

import pytest
import pytest_asyncio

_BACKEND = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend")
if _BACKEND not in sys.path:
    sys.path.insert(0, _BACKEND)

from httpx import ASGITransport, AsyncClient  # noqa: E402
from sqlalchemy import text  # noqa: E402

from app.api import webhooks  # noqa: E402
from app.bots import teams  # noqa: E402
from app.core.database import AsyncSessionLocal, engine  # noqa: E402
from app.main import app  # noqa: E402
from app.models.models import Tenant, User  # noqa: E402
from app.services import message_service, pipeline_client  # noqa: E402

pytestmark = pytest.mark.asyncio

_HEADERS = {"Authorization": "Bearer test-token", "Content-Type": "application/json"}


async def _db_available() -> bool:
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        return True
    except Exception:
        return False


async def _schema_present() -> bool:
    async with engine.connect() as conn:
        twm = (await conn.execute(text("SELECT to_regclass('teams_workspace_map')"))).scalar()
        preq = (await conn.execute(text("SELECT to_regclass('processed_requests')"))).scalar()
    return twm is not None and preq is not None


async def _ok_verify(_auth_header):
    return True


@pytest_asyncio.fixture(autouse=True)
async def _db_lifecycle():
    if not await _db_available():
        pytest.skip("Postgres not reachable — start it with `docker compose up -d postgres`")
    yield
    await engine.dispose()


@pytest_asyncio.fixture
async def client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac


def _activity(**overrides) -> dict:
    base = {
        "type": "message",
        "id": f"a{uuid.uuid4().hex[:10]}",
        "text": "hello",
        "serviceUrl": "https://smba.example.com/",
        "conversation": {"id": "19:conv@thread.tacv2"},
        "from": {"id": "29:user", "aadObjectId": "aad-user-1", "name": "Alice"},
        "recipient": {"id": "28:bot"},
        "channelData": {"tenant": {"id": "aad-tenant-1"}},
    }
    base.update(overrides)
    return base


# ── Fast-path tests (no M14 schema needed) ───────────────────────────────────

async def test_missing_jwt_401(client):
    r = await client.post("/webhooks/teams/messages", content=json.dumps(_activity()),
                          headers={"Content-Type": "application/json"})
    assert r.status_code == 401


async def test_non_message_activity_noop(client, monkeypatch):
    monkeypatch.setattr(webhooks, "_verify_teams_jwt", _ok_verify)
    payload = _activity(type="conversationUpdate")
    r = await client.post("/webhooks/teams/messages", content=json.dumps(payload), headers=_HEADERS)
    assert r.status_code == 200
    assert r.json() == {"ok": True}


async def test_bot_loopguard_noop(client, monkeypatch):
    monkeypatch.setattr(webhooks, "_verify_teams_jwt", _ok_verify)
    # from.id == recipient.id → the bot's own echo → no-op
    payload = _activity(**{"from": {"id": "28:bot"}, "recipient": {"id": "28:bot"}})
    r = await client.post("/webhooks/teams/messages", content=json.dumps(payload), headers=_HEADERS)
    assert r.status_code == 200
    assert r.json() == {"ok": True}


async def test_missing_fields_noop(client, monkeypatch):
    monkeypatch.setattr(webhooks, "_verify_teams_jwt", _ok_verify)
    # No "id" → dedup skipped → field validation returns 200 without touching M14 tables.
    payload = {"type": "message", "from": {"id": "29:u"}, "recipient": {"id": "28:bot"}}
    r = await client.post("/webhooks/teams/messages", content=json.dumps(payload), headers=_HEADERS)
    assert r.status_code == 200
    assert r.json() == {"ok": True}


# ── End-to-end tests (need migration 0004 + monkeypatched delivery/pipeline) ──

@pytest_asyncio.fixture
async def teams_user(monkeypatch):
    if not await _schema_present():
        pytest.skip("M14 schema absent — run `alembic upgrade head` (migration 0004)")
    monkeypatch.setattr(webhooks, "_verify_teams_jwt", _ok_verify)
    slug = f"test-{uuid.uuid4().hex[:8]}"
    aad_tenant = f"aad-{uuid.uuid4().hex[:8]}"
    aad_user = f"aaduser-{uuid.uuid4().hex[:8]}"
    async with AsyncSessionLocal() as db:
        tenant = Tenant(name="Teams Test", slug=slug)
        db.add(tenant)
        await db.flush()
        user = User(
            tenant_id=tenant.id,
            email=f"teams-{uuid.uuid4().hex[:8]}@example.com",
            hashed_password="x",
            role="user",
            teams_user_id=aad_user,
        )
        db.add(user)
        await db.flush()
        await db.execute(
            text("INSERT INTO teams_workspace_map (aad_tenant_id, tenant_id) VALUES (:a, :t)"),
            {"a": aad_tenant, "t": tenant.id},
        )
        await db.commit()
        tenant_id, user_id = tenant.id, user.id

    yield {"aad_tenant_id": aad_tenant, "teams_user_id": aad_user,
           "tenant_id": tenant_id, "user_id": user_id}

    async with AsyncSessionLocal() as db:
        await db.execute(text("DELETE FROM teams_workspace_map WHERE aad_tenant_id = :a"), {"a": aad_tenant})
        await db.execute(text("DELETE FROM users WHERE tenant_id = :t"), {"t": tenant_id})
        await db.execute(text("DELETE FROM tenants WHERE id = :t"), {"t": tenant_id})
        await db.commit()


async def _count_messages(user_id) -> int:
    async with AsyncSessionLocal() as db:
        return (await db.execute(text("""
            SELECT count(*) FROM chat_messages m
            JOIN conversations c ON c.id = m.conversation_id
            WHERE c.user_id = :u
        """), {"u": user_id})).scalar()


def _msg(teams_user, **overrides) -> dict:
    return _activity(
        **{"from": {"id": "29:user", "aadObjectId": teams_user["teams_user_id"]},
           "channelData": {"tenant": {"id": teams_user["aad_tenant_id"]}},
           **overrides},
    )


async def _mock_pipeline(payload):
    return {"answer": "mock answer", "sources": [], "follow_up_questions": []}


async def _fail_pipeline(payload):
    raise AssertionError("pipeline must not be called on reset")


async def test_teams_happy_path_posts_reply_and_saves(client, teams_user, monkeypatch):
    posted = []

    async def _capture(service_url, conv_id, ans, src, reply_to=None):
        posted.append((conv_id, ans))

    monkeypatch.setattr(teams, "send_reply", _capture)
    monkeypatch.setattr(pipeline_client, "call_pipeline", _mock_pipeline)

    r = await client.post("/webhooks/teams/messages",
                          content=json.dumps(_msg(teams_user, text="hello")), headers=_HEADERS)
    assert r.status_code == 200
    assert posted, "expected a reply posted back to Teams"
    assert await _count_messages(teams_user["user_id"]) == 2  # user + assistant


async def test_teams_reset_recreates_without_pipeline(client, teams_user, monkeypatch):
    texts = []

    async def _capture_text(service_url, conv_id, t, reply_to=None):
        texts.append(t)

    monkeypatch.setattr(teams, "send_text", _capture_text)
    monkeypatch.setattr(pipeline_client, "call_pipeline", _fail_pipeline)  # must NOT be called

    r = await client.post("/webhooks/teams/messages",
                          content=json.dumps(_msg(teams_user, text="/new")), headers=_HEADERS)
    assert r.status_code == 200
    assert texts == [message_service.RESET_CONFIRMATION]
    assert await _count_messages(teams_user["user_id"]) == 0  # reset saves nothing


async def test_teams_duplicate_activity_id_noop(client, teams_user, monkeypatch):
    calls = []

    async def _capture(*a, **k):
        calls.append(1)

    monkeypatch.setattr(teams, "send_reply", _capture)
    monkeypatch.setattr(pipeline_client, "call_pipeline", _mock_pipeline)

    payload = _msg(teams_user, text="hello")
    activity_id = payload["id"]
    await client.post("/webhooks/teams/messages", content=json.dumps(payload), headers=_HEADERS)
    await client.post("/webhooks/teams/messages", content=json.dumps(payload), headers=_HEADERS)
    assert len(calls) == 1  # second delivery deduped

    async with AsyncSessionLocal() as db:
        await db.execute(text("DELETE FROM processed_requests WHERE request_id = :r"), {"r": activity_id})
        await db.commit()
