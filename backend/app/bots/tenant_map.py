"""
Phone number to tenant ID mapping.
Owner: M12 — implement DB queries.
"""
import logging
from typing import Optional

logger = logging.getLogger(__name__)


async def get_tenant_for_phone(phone_number: str) -> Optional[str]:
    """
    M12: Implement — query whatsapp_tenant_map table.
    Returns tenant_id or None if not registered.
    """
    # M12: implement DB query
    logger.warning(f"Phone {phone_number} not mapped — M12: implement get_tenant_for_phone()")
    return None


async def register_phone_for_tenant(phone_number: str, tenant_id: str) -> None:
    """M12: INSERT INTO whatsapp_tenant_map (phone_number, tenant_id) VALUES ($1, $2)"""
    # M12: implement
    pass
