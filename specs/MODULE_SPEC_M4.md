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
