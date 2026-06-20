# MODULE_SPEC_M14 — Microsoft Teams Bot

**Owner**: Himanshu + Yashas | **Track**: Bot | **Branch**: `feat/teams-bot`
**Status**: Draft — Source of Truth for M14 implementation
**Date**: 2026-06-20

---

## 1. Role

Microsoft Teams channel end-to-end: receive a message activity from the Bot
Framework → resolve identity → call the RAG pipeline → reply via the Bot Connector
API. Teams workspace → tenant mapping. Conversation memory.

**Teams is modelled on Slack, not WhatsApp.** It is an HTTP webhook + async
reply-back channel (exactly like Slack's Events API), *not* a synchronous TwiML
channel like WhatsApp. M14 reuses the existing channel-agnostic core
(`services/message_service.py`, M4) verbatim and only adds a thin adapter +
delivery module + identity tables — mirroring how Slack was built in M4.

### Why the Slack pattern fits
| Concern | Slack (M4, built) | Teams (M14, this spec) |
|---|---|---|
| Inbound | `POST /webhooks/slack/events` | `POST /webhooks/teams/messages` |
| Inbound auth | HMAC-SHA256 (signing secret) | Bot Framework **JWT** (OpenID Connect) |
| Outbound auth | static `SLACK_BOT_TOKEN` | OAuth2 token (App ID + password), refreshed |
| Reply API | `chat.postMessage` | `POST {serviceUrl}/v3/conversations/{id}/activities` |
| Rich format | Block Kit | **Adaptive Cards** |
| Reply target | `channel` + `thread_ts` | `serviceUrl` + `conversationId` |
| Tenant key | `team_id` | AAD tenant id (`channelData.tenant.id`) |
| Dedup key | `event_id` | `activity.id` |
| Handshake | `url_verification` challenge | none (JWT validation) |
| Loop guard | drop `event.bot_id` | drop activities from the bot's own id |

---

## 2. Scope

**In scope:**
- Teams message handling: ACK 200 immediately, process in a `BackgroundTask`,
  reply via the Bot Connector API (same async shape as Slack).
- Bot Framework JWT verification on every inbound request.
- Identity resolution: Teams AAD tenant + user → platform tenant + user.
- Conversation lifecycle and `/new` `/reset` `/clear` — reused from M4 core.
- History: last 10 messages passed to the pipeline — reused from M4 core.
- Admin onboarding endpoint to link a platform user to their Teams identity.
- Adaptive Card rendering of the answer + sources (cap 3 sources).

**Out of scope:** ephemeral file uploads from Teams (v2 — mirror the WhatsApp
ephemeral path later), proactive/notification messages, message extensions, tabs,
streaming, SSO tab auth.

---

## 3. Processing Flow

```
Teams Activity  (POST /webhooks/teams/messages)
  │
  ├─ Step 1: Verify Bot Framework JWT (Authorization: Bearer <token>)
  │           → Invalid: 401
  │           → activity.type != "message": 200 no-op (typing, conversationUpdate…)
  │           → activity.from.id == bot id: 200 no-op (loop guard)
  │           → Dedup: INSERT processed_requests (activity.id) ON CONFLICT DO NOTHING
  │                    rowcount == 0 → 200 no-op (duplicate retry)
  │           → Return 200 ACK immediately; remaining steps run in BackgroundTask
  │
  ├─ Step 2: Resolve identity → (user_id, tenant_id)
  │           teams_workspace_map (aad_tenant_id → tenant_id)
  │           JOIN users (teams_user_id → user_id)  [reuses message_service]
  │
  ├─ Step 3: Find or create conversation for (user_id, "teams")   [M4 core]
  ├─ Step 4: Reset command check (/new /reset /clear)             [M4 core]
  ├─ Step 5: Load last 10 messages                                [M4 core]
  ├─ Step 6: Call pipeline (mock in dev, n8n in prod)             [M4 core]
  ├─ Step 7: Deliver → teams.send_reply(conversation ref, answer, sources)
  └─ Step 8: Save user + assistant rows to chat_messages          [M4 core]
```

Steps 3–6 and 8 are already implemented in `message_service.process_message`.
M14 adds Step 1 (adapter), Step 2 (a `teams` branch in `_resolve_identity`), and
Step 7 (`teams.send_reply`).

---

## 4. Step Details

### Step 1 — Receive & Verify (adapter, `webhooks.py`)

`POST /webhooks/teams/messages`:
- Read the raw body and the `Authorization: Bearer <jwt>` header.
- **Verify the JWT** issued by the Bot Framework (OpenID Connect, issuer
  `https://api.botframework.com`, audience = `TEAMS_APP_ID`). Use the
  `botframework-connector` / `botbuilder-core` SDK's `JwtTokenValidation`, or
  validate against the published JWKS manually. Invalid → `401`.
- Parse the Activity JSON. If `type != "message"` → `200` no-op.
- Loop guard: if `from.id` is the bot's own id → `200` no-op.
- Dedup: `INSERT INTO processed_requests (request_id) VALUES (:activity_id)
  ON CONFLICT DO NOTHING`; `rowcount == 0` → `200` no-op.
- Validate required fields: `id`, `from.aadObjectId` (or `from.id`),
  `text`, `serviceUrl`, `conversation.id`, `channelData.tenant.id`.
  Missing → `200` + log warning (do not trigger Bot Framework retry).
- **Return `200` immediately.** Dispatch the rest as a `BackgroundTask`.

### Step 2 — Resolve Identity (`message_service._resolve_identity`, teams branch)

```sql
SELECT u.id AS user_id, m.tenant_id AS tenant_id
FROM teams_workspace_map m
JOIN users u
  ON u.tenant_id = m.tenant_id
 AND u.teams_user_id = :teams_user_id
WHERE m.aad_tenant_id = :aad_tenant_id
```
- `teams_user_id` = `activity.from.aadObjectId` (stable across the org).
- Failure (workspace or user not mapped) → raise `IdentityResolutionError`,
  log, stop (already ACKed). Optionally post a one-time "you're not registered"
  reply via `teams.send_text`.

### Step 3–6, Step 8 — reused from M4 core
No changes. `ctx.source = "teams"`; conversations are keyed `(user_id, "teams")`.

### Step 7 — Deliver (`bots/teams.py`)

Build a **conversation reference** from the inbound activity
(`service_url`, `conversation.id`, optional `reply_to_id`) and POST a reply:
```
POST {service_url}/v3/conversations/{conversation_id}/activities
Authorization: Bearer <connector OAuth token>
{
  "type": "message",
  "from":         { "id": "<bot id>", "name": "RAG Bot" },
  "recipient":    { "id": "<user id>" },
  "conversation": { "id": "<conversation id>" },
  "attachments": [ <Adaptive Card with answer + up to 3 sources> ]
}
```
Render the answer as markdown text plus a sources `FactSet`/`TextBlock`
(cap 3). Plain-text fallback (`"text"` field) for accessibility.

---

## 5. MessageContext additions (`services/types.py`)

```python
@dataclass
class MessageContext:
    source: str          # "web" | "slack" | "teams"
    ...
    # Teams reply-back + raw identity (None for other sources)
    teams_service_url:      str | None = None
    teams_conversation_id:  str | None = None
    teams_activity_id:      str | None = None
    teams_reply_to_id:      str | None = None
    teams_aad_tenant_id:    str | None = None   # → tenant resolution
    teams_user_id:          str | None = None   # aadObjectId → user resolution
```

---

## 6. Endpoint Contracts

### Teams — `POST /webhooks/teams/messages`
- Invalid/absent Bot Framework JWT → `401`
- `type != "message"` → `200` no-op
- Activity from the bot itself → `200` no-op
- Duplicate `activity.id` → `200` no-op
- Valid message → `200` ACK immediately; answer delivered async via the
  Bot Connector API into the same conversation.

### Teams Onboard — `POST /webhooks/teams/onboard` (admin only)
Links an existing platform user to their Teams identity. Mirror of
`/webhooks/slack/onboard`.

**Headers:** `Authorization: Bearer <JWT>` (admin)

**Request:**
```json
{ "email": "user@example.com", "teams_user_id": "29:1AbC..." }
```
`teams_user_id` is the user's AAD object id. (Unlike Slack there is no
lookup-by-email Graph call without extra Graph permissions, so the id is
supplied directly — captured from the user's first message, or via Graph if
`User.Read.All` is granted later.)

**200 Response:**
```json
{ "teams_user_id": "29:1AbC...", "email": "user@example.com" }
```

**Errors:** `401` bad JWT · `403` non-admin · `404` email not in tenant ·
`409` user already linked.

---

## 7. Database — migration `0004_teams_messaging`

**`teams_workspace_map`** — AAD tenant → platform tenant

| Column | Type | Notes |
|---|---|---|
| aad_tenant_id | VARCHAR(255) PK | `channelData.tenant.id` |
| tenant_id | UUID FK → tenants | `ON DELETE CASCADE`, NOT NULL |
| service_url | VARCHAR(500) | Bot Connector base URL (region-specific) |
| created_at | TIMESTAMPTZ | auto |

**`users.teams_user_id`** — new column

| Column | Type | Notes |
|---|---|---|
| teams_user_id | VARCHAR(255) | UNIQUE, NULLABLE — AAD object id |

**Reuse existing:** `processed_requests` (dedup on `activity.id`),
`conversations` (`channel = "teams"`), `chat_messages`.

> Update the `conversations.channel` comment in `models.py` to
> `web | whatsapp | slack | teams`. No structural change to that table.

---

## 8. Files

| File | Action | Responsibility |
|---|---|---|
| `backend/app/bots/teams.py` | **New** | Delivery: Bot Connector OAuth token (cached), `send_reply()`, `send_text()`, Adaptive Card builder |
| `backend/app/api/webhooks.py` | Modify | Add `POST /webhooks/teams/messages` adapter + `POST /webhooks/teams/onboard` |
| `backend/app/services/message_service.py` | Modify | `teams` branch in `_resolve_identity`; `teams` delivery in Step 7 + reset confirmation |
| `backend/app/services/types.py` | Modify | Teams fields on `MessageContext` |
| `backend/app/core/config.py` | Modify | `TEAMS_APP_ID`, `TEAMS_APP_PASSWORD`, `TEAMS_TENANT_ID` |
| `backend/app/models/models.py` | Modify | `users.teams_user_id` column; channel comment |
| `backend/alembic/versions/0004_teams_messaging.py` | **New** | `teams_workspace_map` table + `users.teams_user_id` |
| `backend/app/schemas/webhook.py` | Modify | `TeamsOnboardRequest` / `TeamsOnboardResponse` |
| `teams-app/manifest.json` + icons | **New** | Teams app package (sideload/publish) |
| `tests/test_teams_webhook.py` | **New** | JWT path, dedup, identity, delivery |

> **Ownership note:** `webhooks.py` and `message_service.py` are M4-owned.
> M14 changes there require an M4 PR review (per CLAUDE.md cross-module rule).

---

## 9. Environment Variables

| Variable | Required | Default | Notes |
|---|---|---|---|
| `TEAMS_APP_ID` | Yes (Teams) | `""` | Azure Bot Microsoft App ID (= JWT audience) |
| `TEAMS_APP_PASSWORD` | Yes (Teams) | `""` | App client secret — Connector OAuth |
| `TEAMS_TENANT_ID` | No | `""` | AAD tenant id for single-tenant bots |

Add the same keys to `.env.example`. Connector token endpoint:
`https://login.microsoftonline.com/botframework.com/oauth2/v2.0/token`
(scope `https://api.botframework.com/.default`).

---

## 10. Azure / Teams Setup (no code)

```
1. Azure Portal → create an "Azure Bot" resource.
   → Record Microsoft App ID + create a client secret (App password).
2. Bot → Channels → add "Microsoft Teams".
3. Bot → Configuration → Messaging endpoint:
   https://<your-host>/webhooks/teams/messages
   (use an ngrok / dev-tunnel URL during development)
4. Build the Teams app package (teams-app/):
   - manifest.json (bot id = TEAMS_APP_ID, scopes: personal + team)
   - color.png (192x192) + outline.png (32x32)
   - zip the three files
5. Teams client → Apps → Manage your apps → Upload a custom app → sideload the zip.
6. Chat with the bot 1:1 or @mention it in a channel to test.
```

---

## 11. Day-by-Day Deliverables

| Day | Deliverable | Done? |
|---|---|---|
| 1 | Azure Bot resource + App ID/secret. Dev tunnel. Echo activity round-trips. | ☐ |
| 1 | Migration `0004_teams_messaging`; pre-seed one `teams_workspace_map` row. | ☐ |
| 2 | `bots/teams.py`: Connector OAuth token + `send_text()`. Bot replies "pong". | ☐ |
| 2 | `/webhooks/teams/messages` adapter: JWT verify + dedup + ACK + BackgroundTask. | ☐ |
| 3 | `MessageContext` teams fields + `_resolve_identity` teams branch → mock pipeline answer delivered. | ☐ |
| 3 | Adaptive Card in `send_reply()` (answer + ≤3 sources). | ☐ |
| 4 | Conversation memory + `/new` `/reset` `/clear` working in Teams (multi-turn test). | ☐ |
| 4 | `/webhooks/teams/onboard` admin endpoint + `TeamsOnboardRequest` schema. | ☐ |
| 5 | Wire real n8n retrieval (`PIPELINE_URL`). Identity-resolution failure UX. | ☐ |
| 5 | Tests: JWT reject, dedup, identity, delivery. Live test in Teams client. | ☐ |
| 6 | Demo polish: Teams app icons/manifest, publish to org or keep sideloaded; pre-stage 3 sample queries. | ☐ |

---

## 12. Acceptance Criteria

1. Valid Teams message → ACKs `200` within 3s; answer posted back into the same conversation.
2. Missing/invalid Bot Framework JWT → `401`, nothing downstream runs.
3. Non-`message` activity (typing, conversationUpdate) → `200` no-op.
4. Activity from the bot itself → `200` no-op (no reply loop).
5. Duplicate `activity.id` → `200` no-op, no duplicate processing.
6. Unmapped AAD tenant / user → no crash; logged; optional "not registered" reply.
7. `/new` in Teams → conversation + messages deleted, new one created, confirmation posted, pipeline NOT called.
8. Multi-turn conversation → pipeline receives last 10 messages as history.
9. Answer renders as an Adaptive Card with ≤3 sources; plain-text fallback present.
10. Pipeline failure/timeout → fallback message delivered, nothing saved to `chat_messages`.
11. `POST /webhooks/teams/onboard` (admin) links email → `teams_user_id`; non-admin → `403`; already-linked → `409`.
12. Tenant isolation: a Teams user in tenant A never receives tenant B's chunks.

---

## 13. Skills Required
- **Must-have:** Microsoft Bot Framework (Python `botbuilder-core` /
  `botframework-connector`), Azure Bot Service, OAuth2 client-credentials,
  Adaptive Cards, async Python + httpx, Alembic.
- **Nice-to-have:** Microsoft Graph (lookup-by-email onboarding), Teams app
  manifest authoring, proactive messaging.

## 14. Learning Resources
- Bot Framework REST (Connector API): https://learn.microsoft.com/azure/bot-service/rest-api/bot-framework-rest-connector-api-reference
- Send/receive Teams messages: https://learn.microsoft.com/microsoftteams/platform/bots/how-to/conversations/conversation-basics
- Authentication (JWT in/out): https://learn.microsoft.com/azure/bot-service/rest-api/bot-framework-rest-connector-authentication
- Adaptive Cards: https://adaptivecards.io/
- Teams app manifest schema: https://learn.microsoft.com/microsoftteams/platform/resources/schema/manifest-schema
