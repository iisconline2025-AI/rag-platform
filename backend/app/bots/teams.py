"""Microsoft Teams delivery (M14).

Posts answers back to Teams via the Bot Framework Connector API
(`POST {serviceUrl}/v3/conversations/{conversationId}/activities`), mirroring the
Slack delivery module. Outbound auth uses an OAuth2 client-credentials token
fetched from the Bot Framework login endpoint and cached until shortly before it
expires. `TEAMS_APP_ID` / `TEAMS_APP_PASSWORD` are read from settings.
"""
import logging
import time

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

_TOKEN_URL = "https://login.microsoftonline.com/botframework.com/oauth2/v2.0/token"
_TOKEN_SCOPE = "https://api.botframework.com/.default"
_MAX_SOURCES = 3
_BOT_NAME = "RAG Bot"

# Module-level token cache: (access_token, expires_at_epoch). Refreshed lazily.
_token_cache: tuple[str, float] | None = None
# Refresh this many seconds before the real expiry to avoid edge-of-expiry 401s.
_TOKEN_SKEW_SECONDS = 60.0


class TeamsAPIError(Exception):
    """Raised when the Bot Connector API returns a non-2xx response."""


async def _get_connector_token() -> str:
    """Return a cached Bot Connector OAuth token, fetching a new one if expired."""
    global _token_cache
    now = time.time()
    if _token_cache is not None and _token_cache[1] - _TOKEN_SKEW_SECONDS > now:
        return _token_cache[0]

    data = {
        "grant_type": "client_credentials",
        "client_id": settings.TEAMS_APP_ID,
        "client_secret": settings.TEAMS_APP_PASSWORD,
        "scope": _TOKEN_SCOPE,
    }
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(_TOKEN_URL, data=data)
            resp.raise_for_status()
            payload = resp.json()
    except httpx.HTTPError as exc:
        raise TeamsAPIError(f"Connector token request failed: {exc}") from exc

    token = payload.get("access_token")
    if not token:
        raise TeamsAPIError("Connector token response missing access_token")
    expires_in = float(payload.get("expires_in", 3600))
    _token_cache = (token, now + expires_in)
    return token


def _build_card(answer: str, sources: list) -> dict:
    """Build an Adaptive Card attachment with the answer + up to 3 sources."""
    body: list[dict] = [
        {"type": "TextBlock", "text": answer, "wrap": True}
    ]
    if sources:
        facts = [
            {
                "title": s.get("title", "source"),
                "value": f"p.{s.get('page_number', '?')}",
            }
            for s in sources[:_MAX_SOURCES]
        ]
        body.append({"type": "TextBlock", "text": "Sources", "weight": "Bolder",
                     "spacing": "Medium", "wrap": True})
        body.append({"type": "FactSet", "facts": facts})

    return {
        "contentType": "application/vnd.microsoft.card.adaptive",
        "content": {
            "type": "AdaptiveCard",
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "version": "1.4",
            "body": body,
        },
    }


async def send_text(
    service_url: str, conversation_id: str, text: str, reply_to_id: str | None = None
) -> None:
    """Post a plain-text message into a Teams conversation."""
    await _post_activity(service_url, conversation_id, {
        "type": "message",
        "text": text[:4000],
        **({"replyToId": reply_to_id} if reply_to_id else {}),
    })


async def send_reply(
    service_url: str,
    conversation_id: str,
    answer: str,
    sources: list,
    reply_to_id: str | None = None,
) -> None:
    """Post an answer as an Adaptive Card (with a plain-text fallback)."""
    await _post_activity(service_url, conversation_id, {
        "type": "message",
        "text": answer[:4000],                       # fallback for clients without cards
        "attachments": [_build_card(answer, sources)],
        **({"replyToId": reply_to_id} if reply_to_id else {}),
    })


async def _post_activity(service_url: str, conversation_id: str, activity: dict) -> None:
    """POST an activity to the Bot Connector. Logs (does not raise) on failure."""
    base = service_url.rstrip("/")
    url = f"{base}/v3/conversations/{conversation_id}/activities"
    activity.setdefault("from", {"id": settings.TEAMS_APP_ID, "name": _BOT_NAME})
    activity.setdefault("conversation", {"id": conversation_id})
    try:
        token = await _get_connector_token()
    except TeamsAPIError as exc:
        logger.error("Teams connector token unavailable: %s", exc)
        return
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json; charset=utf-8",
    }
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(url, json=activity, headers=headers)
        if resp.status_code >= 300:
            logger.error("Teams activity POST failed (%s): %s", resp.status_code, resp.text[:300])
    except httpx.HTTPError as exc:
        logger.error("Teams activity POST transport error: %s", exc)
