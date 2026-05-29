"""
Seed script — creates demo tenant + admin user.
Owner: M2 — implement create_admin().
Run: python -m app.scripts.seed_admin
"""
import asyncio
import logging
import sys
import os

# Add backend dir to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

from app.core.config import settings
from app.core.security import get_password_hash

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def create_admin():
    """
    M2: Implement using SQLAlchemy async session:
    1. Check if tenant with slug=SEED_TENANT_SLUG exists
    2. If not, create Tenant(name=SEED_TENANT_NAME, slug=SEED_TENANT_SLUG)
    3. Check if user with email=SEED_ADMIN_EMAIL exists
    4. If not, create User(email, hashed_password, role='super_admin', tenant_id)
    5. Log success
    """
    logger.info(f"Seeding admin: {settings.SEED_ADMIN_EMAIL}")
    logger.info(f"Tenant: {settings.SEED_TENANT_NAME} ({settings.SEED_TENANT_SLUG})")
    # M2: implement DB operations
    logger.warning("M2: implement seed_admin.py DB operations")
    logger.info("✅ Seed complete (mock)")


if __name__ == "__main__":
    asyncio.run(create_admin())
