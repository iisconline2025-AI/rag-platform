# MODULE_SPEC_M13 — Customer Onboarding Platform

**Owner**: Member 13 | **Track**: Platform | **Branch**: `feat/onboarding`

## Role
Multi-tenant self-service onboarding wizard: company registration → admin user → first document → ready to query. Tenant management admin page. Customer isolation demo.

## Day-by-Day Deliverables
| Day | Deliverable | Done? |
|---|---|---|
| 1 | Design tenant onboarding flow. Wireframe wizard steps. Branch. | ☐ |
| 2 | `POST /onboarding/register` API — create tenant + admin user + return JWT | ☐ |
| 2 | `GET /onboarding/check-slug` — check slug availability | ☐ |
| 2 | Onboarding wizard Step 1 in Next.js (company info form) | ☐ |
| 3 | Wizard Steps 2 (user setup) + 3 (first document upload) | ☐ |
| 3 | Tenant management admin page: list + create + deactivate tenants | ☐ |
| 4 | Full onboarding E2E: register → upload → query works | ☐ |
| 5 | Tenant isolation demo: show Tenant A cannot see Tenant B's docs | ☐ |
| 6 | Customer landing page at `/` with "Get Started" → `/onboarding` | ☐ |

## Files Owned
- `backend/app/api/onboarding.py`
- `frontend/src/app/onboarding/`

## Onboarding Wizard Steps
```
Step 1: Company Information
  ┌──────────────────────────────┐
  │ Company Name: [___________]  │
  │ Company Slug: [___________]  │ ← auto-check availability
  │ Plan:         [Free ▼]       │
  └──────────────────────────────┘

Step 2: Admin User
  ┌──────────────────────────────┐
  │ Email:    [________________] │
  │ Password: [________________] │
  │ Confirm:  [________________] │
  └──────────────────────────────┘

Step 3: Upload First Document (Optional)
  ┌──────────────────────────────┐
  │  Drop your first PDF here    │
  │  or click to browse          │
  │                              │
  │  [Skip for now]  [Upload →]  │
  └──────────────────────────────┘

Step 4: Done! 🎉
  ┌──────────────────────────────┐
  │ Your knowledge base is ready │
  │ [Go to Chat] [Upload More]   │
  └──────────────────────────────┘
```

## API Implementation
```python
# backend/app/api/onboarding.py
@router.post("/register", status_code=201)
async def register_tenant(payload: OnboardingRegisterRequest, db: AsyncSession = Depends(get_db)):
    # 1. Check slug is unique
    # 2. CREATE tenant
    # 3. CREATE admin user (role='admin') with hashed password
    # 4. Generate JWT for admin user
    # 5. Return {tenant, admin_user, access_token}
    ...

@router.get("/check-slug")
async def check_slug(slug: str, db: AsyncSession = Depends(get_db)):
    exists = await db.execute(select(Tenant).where(Tenant.slug == slug))
    return {"available": exists.scalar() is None}
```

## Acceptance Criteria
- [ ] New tenant registers at `/onboarding` in < 2 minutes
- [ ] Slug uniqueness validated in real-time (on blur)
- [ ] After Step 3 (or Skip), user lands on chat portal pre-authenticated
- [ ] Uploaded first document is ingested and queryable within 2 minutes
- [ ] Tenant admin page shows all tenants (super_admin only)
- [ ] Deactivating a tenant prevents their users from logging in
- [ ] E2E onboarding tested with all 3 demo companies (M11's demo dataset)
