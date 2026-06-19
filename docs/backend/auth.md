# Auth API

The authentication module handles user login, registration, and profile retrieval using stateless JWT tokens.

**Owner**: M2 · **Files**: `backend/app/api/auth.py`, `backend/app/core/security.py`, `backend/app/core/dependencies.py`, `backend/app/schemas/auth.py`

## Endpoints

### POST `/auth/login`

Authenticate a user and receive a JWT token.

**Rate limited**: 5 requests/minute per IP.

**Request Body**:
```json
{
  "email": "admin@iisc-demo.com",
  "password": "changeme-strong-password"
}
```

**Response** (`200 OK`):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "user": {
    "id": "1d73fb60-cb7f-4463-ae57-33336e3a350c",
    "email": "admin@iisc-demo.com",
    "role": "super_admin",
    "tenant_id": "83d5f2cf-e28a-48fa-8092-367735a99c1d",
    "is_active": true,
    "created_at": "2026-06-01T04:26:15.423433Z"
  }
}
```

**Error Responses**:
- `401` — Invalid email or password / Account disabled
- `429` — Rate limit exceeded

### POST `/auth/register`

Create a new user within a tenant. **Requires admin role.**

A tenant admin can only create users in their own tenant. `super_admin` can target any tenant.

**Headers**: `Authorization: Bearer <token>`

**Request Body**:
```json
{
  "email": "analyst@iisc-demo.com",
  "password": "a-strong-password",
  "tenant_id": "83d5f2cf-e28a-48fa-8092-367735a99c1d",
  "role": "user"
}
```

**Response** (`201 Created`): `UserOut` object.

**Error Responses**:
- `401` — Not authenticated
- `403` — Insufficient permissions / Cannot create users outside your tenant
- `404` — Tenant not found
- `409` — Email already registered

### GET `/auth/me`

Return the profile of the currently authenticated user.

**Headers**: `Authorization: Bearer <token>`

**Response** (`200 OK`): `UserOut` object.

### POST `/auth/logout`

Stateless JWT — logout is a client-side token discard. This endpoint exists for API completeness.

**Headers**: `Authorization: Bearer <token>`

**Response** (`200 OK`):
```json
{"message": "Logged out"}
```

## Dependencies

### `get_current_user`

FastAPI dependency that decodes the Bearer JWT, loads the user from the database, and verifies the account is active.

```python
from app.core.dependencies import get_current_user

@router.get("/protected")
async def protected_route(user: User = Depends(get_current_user)):
    ...
```

### `require_role`

Dependency factory for role-based access control. `super_admin` always passes.

```python
from app.core.dependencies import require_role

@router.post("/admin-only")
async def admin_route(_admin: User = Depends(require_role("admin"))):
    ...
```

## Tests

12 integration tests in `tests/test_auth.py`:

- Login success / wrong password / unknown email
- `/me` with valid token / no token / garbage token / expired token
- Register requires auth / admin creates user / cross-tenant forbidden
- Logout with token
- Login rate limit (429 on 6th rapid request)
