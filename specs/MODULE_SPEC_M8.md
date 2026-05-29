# MODULE_SPEC_M8 — Frontend: Admin Portal

**Owner**: Member 8 | **Track**: Frontend | **Branch**: `feat/admin-ui`

## Role
Next.js admin dashboard: login, document upload, document management, user management, tenant settings.

## Day-by-Day Deliverables
| Day | Deliverable | Done? |
|---|---|---|
| 1 | Set up Next.js 14 + TailwindCSS + project structure. Branch. | ☐ |
| 2 | Generate API client from `specs/openapi.yaml` (openapi-typescript-codegen) | ☐ |
| 2 | Login page + JWT auth context (cookie storage) | ☐ |
| 2 | Admin layout: sidebar (Documents, Users, Tenants) + header | ☐ |
| 2 | Document upload page: drag-drop + URL input form | ☐ |
| 3 | Document list page: table with status badges (pending/processing/completed/failed) | ☐ |
| 3 | Document detail page: metadata, chunk count, delete button | ☐ |
| 4 | Wire to real backend: login flow + protected routes + real data | ☐ |
| 5 | User management page: list users, invite form | ☐ |
| 5 | Polish: loading states, error handling, toast notifications | ☐ |
| 6 | Responsive design, final UI review | ☐ |

## Files Owned
- `frontend/src/app/admin/`
- `frontend/src/components/admin/`

## Key Pages
```
/admin/login          → login form
/admin/documents      → document list with upload button
/admin/documents/[id] → document detail
/admin/users          → user list + invite
/admin/tenants        → tenant list (super_admin only)
/admin/settings       → tenant settings
```

## API Client Setup
```bash
npx openapi-typescript-codegen \
  --input ../specs/openapi.yaml \
  --output src/lib/api \
  --client axios
```

## Auth Context
```typescript
// src/lib/auth.tsx
// Store JWT in httpOnly cookie via /api/auth/callback route
// Provide useAuth() hook: { user, token, login, logout }
// Redirect to /admin/login if not authenticated
```

## Document Status Badge Colors
```typescript
const statusColors = {
  pending: 'yellow',
  processing: 'blue',
  completed: 'green',
  failed: 'red'
}
```

## Acceptance Criteria
- [ ] Login with `admin@example.com` (seed data) works
- [ ] Upload PDF → status shows `processing` → updates to `completed`
- [ ] Document list paginated with real data from backend
- [ ] Delete document removes it from list
- [ ] Invite user form posts to `POST /admin/users/invite`
- [ ] Unauthorized access redirects to login
- [ ] Loading spinners during API calls
- [ ] Error toast on API failure
