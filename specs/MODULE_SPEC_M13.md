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


---
<!-- AUTO-APPENDED:SKILLS-V1 -->
## Skills Required
- **Must-have:** FastAPI, Next.js multi-step forms, validation (Pydantic + zod), file upload, tenant isolation patterns.
- **Nice-to-have:** Stripe (stretch — paid plans), email service (Resend/Postmark) for welcome mail.

## Detailed Step-by-Step Plan
### Day 1 — Design
1. Branch `feat/onboarding`. Wireframe 3-step wizard:
   - Step 1: Company info (name, slug, industry).
   - Step 2: Admin user (name, email, password).
   - Step 3: Upload first document → "You're ready! Open chat →".
2. Draft DB extensions if any (most schema already present in `tenants` + `users`).

### Day 2 — Backend
3. `backend/app/api/onboarding.py`:
   - `POST /onboarding/signup` — accepts `{company_name, slug, admin_email, admin_password, industry}`; creates tenant + super_admin user; returns JWT.
   - `GET /onboarding/check-slug?slug=foo` — returns `{available: bool}`.
4. Enforce slug uniqueness + reserved-word blocklist (`admin`, `api`, `www`).

### Day 3 — Frontend Wizard
5. `app/onboarding/page.tsx`: stepper component, useState for wizard data, validation per step (zod).
6. Step 1: company form + live slug availability check (debounced 500 ms).
7. Step 2: password strength meter; show terms checkbox.
8. Step 3: drag-drop one file → POST /admin/documents/upload (uses fresh JWT) → "Setting up…" loading state.

### Day 4 — Post-onboarding Redirect
9. After step 3: redirect to `/chat` with conversation pre-created and a system "Welcome — try asking…" message.

### Day 5 — Multi-tenant Isolation Test
10. Coordinate with M10: write `tests/test_onboarding_isolation.py` — onboard tenant A, onboard tenant B, confirm B cannot see A's document.

### Day 6 — Landing Page
11. `app/page.tsx`: marketing landing — hero, 3 features, "Get started" CTA → /onboarding. Static HTML, no logic.

## Learning Resources
- Multi-step forms in React: https://www.smashingmagazine.com/2021/04/multi-step-form-react/
- Zod validation: https://zod.dev/
- Slug generation: https://github.com/Trott/slug
