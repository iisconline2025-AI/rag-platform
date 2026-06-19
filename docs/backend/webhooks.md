# Webhooks API

The webhooks module handles incoming messages from WhatsApp (Twilio), Slack, and status callbacks from n8n.

**Owner**: M4 · **File**: `backend/app/api/webhooks.py`

:::{admonition} Implementation Status
:class: warning

All three webhook handlers are currently **minimal stubs** (M4 owns). The route scaffolds exist and accept requests, but business logic is not yet implemented. See the TODO items below for each endpoint.
:::

## Endpoints

### POST `/webhooks/whatsapp`

Receives incoming WhatsApp messages from Twilio.

**Current state**: Parses `Body` and `From` from form data, returns a placeholder TwiML response. No signature validation, no tenant lookup, no RAG query.

**Planned flow** (M4 + M12 to implement):
1. Twilio sends webhook with message body + media URLs
2. ~~FastAPI validates Twilio signature (reject unsigned requests)~~ → **TODO: add `twilio.request_validator`**
3. ~~Look up tenant via `whatsapp_tenant_map` table~~ → **TODO: M12 `tenant_map.py` is a stub**
4. If message contains a file attachment → trigger ephemeral ingestion
5. Otherwise → call n8n retrieval → format TwiML reply

### POST `/webhooks/slack/events`

Handles Slack `app_mention` events.

**Current state**: Handles URL verification challenge only. Returns `{"ok": true}` for all other events. No HMAC verification, no RAG query.

**Planned flow** (M4 to implement):
1. ~~Verify Slack HMAC signature~~ → **TODO: add `slack_sdk.signature.SignatureVerifier`**
2. Handle `app_mention` events → call RAG → post reply in thread

### POST `/webhooks/n8n/ingestion-status`

Callback from n8n after document ingestion completes or fails.

**Current state**: Reads `document_id` and `status` from body, returns acknowledgment. **Does not** validate `callback_token` or update the database.

**Planned request body**:
```json
{
  "document_id": "uuid",
  "status": "completed",
  "chunk_count": 42,
  "error_message": null,
  "callback_token": "<N8N_CALLBACK_TOKEN>"
}
```

**TODO** (M4/M3 to implement):
1. ~~Validate `callback_token` matches `settings.N8N_CALLBACK_TOKEN`~~ → **not yet coded**
2. ~~Update `documents` table: set `status` and `chunk_count`~~ → **not yet coded**
3. If failed, store `error_message`
