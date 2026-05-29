"""
Auth API routes — login, register, me, logout.
Owner: M2 — implement the route bodies.
Skeleton provided — add DB queries and JWT logic.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


@router.post("/login", summary="Login and get JWT token")
async def login(request: dict):
    """
    M2: Implement:
    1. Look up user by email in DB
    2. verify_password(request.password, user.hashed_password)
    3. create_access_token({"sub": str(user.id), "tenant_id": str(user.tenant_id)})
    4. Return LoginResponse
    """
    raise HTTPException(status_code=501, detail="M2: implement login endpoint")


@router.post("/register", status_code=201, summary="Register new user")
async def register(request: dict):
    """M2: Implement user creation with hashed password."""
    raise HTTPException(status_code=501, detail="M2: implement register endpoint")


@router.get("/me", summary="Get current user")
async def get_me(token: str = Depends(oauth2_scheme)):
    """M2: Decode JWT, load user from DB, return UserOut."""
    raise HTTPException(status_code=501, detail="M2: implement /me endpoint")


@router.post("/logout", summary="Logout")
async def logout(token: str = Depends(oauth2_scheme)):
    """Stateless JWT — logout is a client-side discard.  No server state."""
    return {"message": "Logged out"}
