"""M14: Microsoft Teams messaging schema

- users: add teams_user_id identity column (unique)
- new: teams_workspace_map (aad_tenant_id → tenant_id, mirrors slack_workspace_map)

Reuses processed_requests (dedup on activity.id) and conversations (channel='teams').

Revision ID: 0004_teams_messaging
Revises:     0002_m4_messaging
Create Date: 2026-06-20
Owner:       M14

NOTE: chains off 0002 (dev head). The parallel branch fix/conversations-user-cascade
adds 0003 off the same parent, so once both land run `alembic merge heads`.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "0004_teams_messaging"
down_revision: Union[str, None] = "0002_m4_messaging"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── users: Teams identity column ──────────────────────────────────────────
    op.add_column("users", sa.Column("teams_user_id", sa.String(255), nullable=True))
    op.create_unique_constraint("uq_users_teams_user_id", "users", ["teams_user_id"])
    op.create_index(
        "idx_users_teams",
        "users", ["teams_user_id"],
        postgresql_where=sa.text("teams_user_id IS NOT NULL"),
    )

    # ── teams_workspace_map ───────────────────────────────────────────────────
    op.create_table(
        "teams_workspace_map",
        sa.Column("aad_tenant_id", sa.String(255), nullable=False),
        sa.Column(
            "tenant_id",
            UUID(as_uuid=True),
            sa.ForeignKey("tenants.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("service_url", sa.String(500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.PrimaryKeyConstraint("aad_tenant_id", name="pk_teams_workspace_map"),
    )


def downgrade() -> None:
    op.drop_table("teams_workspace_map")
    op.drop_index("idx_users_teams", table_name="users")
    op.drop_constraint("uq_users_teams_user_id", "users", type_="unique")
    op.drop_column("users", "teams_user_id")
