"""
Webhook routes — WhatsApp (Twilio), Slack Events, n8n callbacks.
Owner: M4 — implement route bodies.
"""
from fastapi import APIRouter, Request, Response, HTTPException

router = APIRouter()


@router.post("/whatsapp", summary="Twilio WhatsApp incoming message")
async def whatsapp_webhook(request: Request):
    """
    M4: Implement:
    1. Validate Twilio signature (Day 5)
    2. Parse form: Body (message text), From (phone number)
    3. Lookup tenant from phone number (M12's tenant_map)
    4. Call chat_query_internal(body, tenant_id)
    5. Return TwiML XML response
    """
    form = await request.form()
    message_body = form.get("Body", "")
    from_number = form.get("From", "")
    # M4: implement real logic
    twiml = f'<?xml version="1.0"?><Response><Message>M4: implement WhatsApp handler. Received: {message_body[:50]}</Message></Response>'
    return Response(content=twiml, media_type="application/xml")


@router.post("/slack/events", summary="Slack Events API webhook")
async def slack_events(request: Request):
    """
    M4: Implement:
    1. Handle URL verification challenge
    2. Verify Slack signature (Day 5)
    3. Handle app_mention events → call RAG → post reply in thread
    """
    body = await request.json()
    # Handle Slack URL verification challenge
    if body.get("type") == "url_verification":
        return {"challenge": body.get("challenge")}
    # M4: implement app_mention handler
    return {"ok": True}


@router.post("/n8n/ingestion-status", summary="n8n ingestion pipeline callback")
async def n8n_ingestion_callback(request: Request):
    """
    M4: Implement:
    1. Parse: {document_id, status, chunk_count, error_message}
    2. UPDATE documents SET status=?, chunk_count=? WHERE id=?
    3. Return 200
    """
    body = await request.json()
    document_id = body.get("document_id")
    status = body.get("status")
    # M4/M3: update document status in DB
    return {"message": f"Status update received: document_id={document_id} status={status}"}
