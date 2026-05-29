"""
WhatsApp bot logic — Twilio integration.
Owner: M12 — implement handle_whatsapp_message and helper functions.
"""
import logging
from typing import Optional
from app.services import n8n_client

logger = logging.getLogger(__name__)


def twiml_reply(message: str) -> str:
    """Format a TwiML XML response for WhatsApp."""
    message = message[:1600]  # WhatsApp character limit
    escaped = message.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    return f'<?xml version="1.0"?><Response><Message>{escaped}</Message></Response>'


async def handle_whatsapp_message(body: str, from_number: str) -> str:
    """
    M12: Implement:
    1. get_tenant_for_phone(from_number)
    2. Load conversation history from DB for this phone number
    3. Call n8n_client.retrieve(body, tenant_id, history)
    4. Save messages to DB
    5. Format and return TwiML
    """
    logger.info(f"WhatsApp message from {from_number}: {body[:50]}")
    # M12: implement full logic
    return twiml_reply("M12: WhatsApp bot not yet implemented. Coming Day 2!")
