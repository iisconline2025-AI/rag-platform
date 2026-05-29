"""
Customer onboarding API — self-service tenant registration.
Owner: M13 — implement route bodies.
"""
from fastapi import APIRouter, HTTPException

router = APIRouter()


@router.post("/register", status_code=201, summary="Register new tenant (self-service)")
async def register_tenant(request: dict):
    """
    M13: Implement:
    1. Check slug uniqueness
    2. CREATE tenant (name, slug, plan)
    3. CREATE admin user (email, hashed_password, role='admin', tenant_id)
    4. create_access_token for admin user
    5. Return {tenant, admin_user, access_token}
    """
    raise HTTPException(status_code=501, detail="M13: implement tenant registration")


@router.get("/check-slug", summary="Check slug availability")
async def check_slug(slug: str):
    """M13: Return {available: bool}."""
    raise HTTPException(status_code=501, detail="M13: implement slug check")
