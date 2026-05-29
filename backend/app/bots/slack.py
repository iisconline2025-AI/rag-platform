"""
Slack bot handler.
Owner: M4 — implement handle_app_mention.
"""
import logging

logger = logging.getLogger(__name__)


async def handle_app_mention(event: dict, tenant_id: str) -> None:
    """
    M4: Implement:
    1. Extract text from event (remove @bot mention)
    2. Call n8n_client.retrieve(text, tenant_id)
    3. Post reply in thread using Slack Web API
    """
    logger.info(f"Slack app_mention event: {event}")
    # M4: implement Slack reply
