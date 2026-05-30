# MODULE_SPEC_M4 — Backend: Webhooks (WhatsApp + Slack)

**Owner**: Member 4 | **Track**: Backend | **Branch**: `feat/webhooks`

## Role
FastAPI webhook routes for WhatsApp (Twilio TwiML), Slack Events API, and n8n callbacks.

## Day-by-Day Deliverables
| Day | Deliverable | Done? |
|---|---|---|
| 1 | Study Twilio WhatsApp + Slack Events API docs. Scaffold 3 POST routes. | ☐ |
| 2 | `POST /webhooks/whatsapp` — parse Twilio, call M3's mock `/chat/query`, return TwiML | ☐ |
| 2 | `POST /webhooks/slack/events` — handle challenge + `app_mention` | ☐ |
| 3 | Wire WhatsApp → real n8n retrieval (when M6 is ready) | ☐ |
| 4 | Slack: post thread reply after RAG response | ☐ |
| 5 | Twilio signature validation + Slack HMAC verification | ☐ |
| 6 | Bug fixes, load test webhook endpoints | ☐ |

## Files Owned
- `backend/app/api/webhooks.py`
- `backend/app/bots/slack.py`

## WhatsApp Webhook Implementation
```python
@router.post("/whatsapp")
async def whatsapp_webhook(request: Request):
    # 1. Validate Twilio signature (Day 5 — skip on Day 2)
    # 2. Parse form data: Body, From, To
    form = await request.form()
    message_body = form.get("Body")
    from_number = form.get("From")   # e.g. "whatsapp:+91xxxxxxxxxx"

    # 3. Lookup tenant from phone number (M12's tenant_map)
    tenant_id = await get_tenant_for_phone(from_number)

    # 4. Call chat query (mock or real)
    response = await chat_query_internal(message_body, tenant_id)

    # 5. Return TwiML
    answer = response["answer"]
    sources = response.get("sources", [])[:2]  # truncate for WA
    twiml = f"""<?xml version="1.0"?><Response><Message>{answer}</Message></Response>"""
    return Response(content=twiml, media_type="application/xml")
```

## Slack Event Handler
```python
# Handle URL verification challenge
# Handle app_mention events
# Call n8n retrieval → post reply in thread using Slack Web API
```

## n8n Callback Handler
```python
@router.post("/n8n/ingestion-status")
async def n8n_ingestion_callback(payload: IngestionStatusPayload, db: AsyncSession = Depends(get_db)):
    # Update documents.status = payload.status
    # Update documents.chunk_count = payload.chunk_count
```

## Acceptance Criteria
- [ ] `POST /webhooks/whatsapp` returns valid TwiML with answer
- [ ] `POST /webhooks/slack/events` handles URL challenge and `app_mention`
- [ ] `POST /webhooks/n8n/ingestion-status` updates document status in DB
- [ ] Twilio signature validated (Day 5)
- [ ] Slack request verified with HMAC-SHA256 (Day 5)

---

## [LOCKED] Locked Scope Update (M1 / 29-May)

**MCP server**: A new `backend/app/mcp/` module exposes platform retrieval as MCP tools (`query_knowledge_base`, `list_documents`). M4 co-owns it with M3.
- Endpoints: `GET /mcp/info`, `POST /mcp/rpc`
- Auth: `X-MCP-API-Key` header
- See `backend/app/mcp/server.py` + `tools.py` for scaffolds committed by M1.
- Demo: Claude Desktop config in `docs/DEMO.md`.

**WhatsApp ephemeral upload**: When Twilio webhook receives a `MediaUrl0` payload:
1. Download media (respect `MAX_WHATSAPP_UPLOAD_BYTES = 10 MB`)
2. Validate via `services/file_validator.py`
3. Save to `/tmp/wa-<uuid>`
4. POST to `N8N_EPHEMERAL_INGEST_WEBHOOK_URL` with `{conversation_id, tenant_id, file_path, source_name, ttl_seconds: 3600}`
5. Acknowledge to user via TwiML, then process the follow-up question against ephemeral + persistent retrieval.

**Slack moved to stretch**: only attempt after WhatsApp + MCP are demo-stable.


---
<!-- AUTO-APPENDED:SKILLS-V1 -->
## Skills Required
- **Must-have:** FastAPI, Twilio Programmable Messaging API, TwiML, HMAC signature validation, Slack Events API + Bolt SDK, ngrok for local webhook testing.
- **Nice-to-have:** Async background tasks, retry/backoff patterns.

## Detailed Step-by-Step Plan
### Day 1 — Setup
1. Branch `feat/webhooks`.
2. Create Twilio account, activate WhatsApp Sandbox (https://console.twilio.com → Messaging → Try it out → WhatsApp), join sandbox from your phone (`join <code>` to the sandbox number).
3. Install ngrok: `choco install ngrok`; `ngrok http 8000` → copy https URL.
4. In Twilio console set sandbox `When a message comes in` to `https://<ngrok>.ngrok-free.app/webhooks/whatsapp`.

### Day 2 — WhatsApp Webhook (text only)
5. Implement `POST /webhooks/whatsapp` to accept `application/x-www-form-urlencoded` (Twilio sends `From`, `Body`, `MediaUrl0`, etc.).
6. Validate Twilio signature using `twilio.request_validator.RequestValidator` and `settings.TWILIO_AUTH_TOKEN` (skip if `settings.DEBUG`).
7. Look up tenant by `From` phone in `whatsapp_tenant_map` table; reject with TwiML error if not mapped.
8. Call `services/n8n_client.retrieve(Body, tenant_id, history=[])` → wrap answer in TwiML `<Message>` and return.
9. Test: send WhatsApp message → see mock answer reply.

### Day 3 — WhatsApp Ephemeral Upload
10. When `MediaUrl0` is present, download with `httpx` (use Twilio basic-auth: account_sid + auth_token).
11. Run `services/file_validator.validate_upload(content, mime)` against 10 MB cap and MIME allowlist.
12. Save to `/tmp/<uuid>.<ext>`.
13. POST to `settings.N8N_EPHEMERAL_INGEST_WEBHOOK_URL` with `{tenant_id, conversation_id, file_path, ttl_minutes: 60}`.
14. Reply with TwiML: `"Got it — I've indexed your file. Ask me anything about it for the next hour."`

### Day 4 — Ingestion Callback
15. Implement `POST /webhooks/ingestion-status` (co-owned with M3) — same handler; verify `X-Callback-Token`.

### Day 5 — Slack (Stretch)
16. `app/bots/slack.py`: implement `POST /webhooks/slack/events`; verify `X-Slack-Signature`; handle `app_mention` event → call retrieve → `chat.postMessage` reply.

### Day 6 — Tests
17. `tests/test_webhooks.py`: mock Twilio request, assert TwiML response shape; test signature rejection (403).

## Learning Resources
- Twilio WhatsApp Quickstart: https://www.twilio.com/docs/whatsapp/quickstart/python
- Twilio request validation: https://www.twilio.com/docs/usage/webhooks/webhooks-security
- Slack Bolt for Python: https://slack.dev/bolt-python/concepts
