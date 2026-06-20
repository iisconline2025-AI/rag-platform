"""Shared data carrier for the unified message service (M4).

All channel adapters normalize their payload into a `MessageContext` before
handing it to `message_service.process_message`.
"""
from dataclasses import dataclass
from uuid import UUID


@dataclass
class MessageContext:
    request_id: str                       # UUID (web) | event_id (Slack) | activity.id (Teams)
    source: str                           # "web" | "slack" | "teams"
    query: str                            # message text
    # Resolved in Step 2 — present on entry for web, filled in for Slack/Teams.
    user_id: UUID | None = None           # internal user ID
    tenant_id: UUID | None = None         # from JWT (web) | *_workspace_map (Slack/Teams)
    conversation_id: UUID | None = None   # set in Step 3
    # Slack reply-back + raw identity (None for web)
    slack_channel: str | None = None
    slack_thread_ts: str | None = None
    slack_team_id: str | None = None      # Slack team_id → tenant resolution
    slack_user_id: str | None = None      # Slack user id → internal user resolution
    # Teams reply-back + raw identity (None for other sources)
    teams_service_url: str | None = None      # Bot Connector base URL (region-specific)
    teams_conversation_id: str | None = None  # Teams conversation reference
    teams_reply_to_id: str | None = None      # activity id to thread the reply under
    teams_aad_tenant_id: str | None = None    # channelData.tenant.id → tenant resolution
    teams_user_id: str | None = None          # from.aadObjectId → internal user resolution
