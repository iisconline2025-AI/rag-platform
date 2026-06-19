# Security Model

## Authentication

- **JWT tokens** — stateless, 24-hour expiry, signed with `JWT_SECRET`
- **bcrypt** password hashing via passlib
- No Redis blacklist — logout is client-side token discard
- Rate-limiting on login: 5 requests/minute per IP (slowapi, in-process)

## Authorization

### Role-Based Access Control

| Role | Permissions |
|:-----|:-----------|
| `super_admin` | Full platform access, manage all tenants |
| `admin` | Manage own tenant: documents, users, settings |
| `user` | Query knowledge base, view conversations |

### Tenant Isolation

- Every database query includes `WHERE tenant_id = :tenant_id`
- Enforced via SQLAlchemy dependency injection (`get_current_user` extracts tenant from JWT)
- Tenant admins **cannot** create users in other tenants (403 guard)
- Verified by M10's multi-tenant isolation test suite

## File Upload Security

Validation logic implemented in `backend/app/services/file_validator.py`:

1. **Size cap** — 25 MB for admin uploads, 10 MB for WhatsApp
2. **MIME allowlist** — `application/pdf`, `application/vnd.openxmlformats-officedocument.wordprocessingml.document`, `text/plain`, `image/png`, `image/jpeg`
3. **Magic-byte verification** — reads first bytes of file to confirm actual format matches declared MIME type (defense-in-depth against spoofed extensions)

:::{admonition} Not Yet Implemented
:class: warning

The following are **configured** in `config.py` but **not yet enforced** in code (the upload handler in `admin.py` is still a 501 stub):

4. **Per-tenant quota** — 1 GB storage cap (`MAX_BYTES_PER_TENANT`). Config exists, enforcement pending M3 upload implementation.
5. **Upload rate limit** — 20 uploads/hour/tenant (`MAX_UPLOADS_PER_HOUR`). Config exists, no middleware wired yet.
:::

## Webhook Security

:::{admonition} Not Yet Implemented
:class: warning

All three webhook security measures below are **planned** per the architecture spec but **not yet coded**. The webhook handlers in `backend/app/api/webhooks.py` are currently stubs. Team members M4 and M12 should implement these before production deployment.
:::

- **Twilio** — signature validation on every WhatsApp webhook (use `twilio.request_validator`)
- **n8n callbacks** — authenticate via shared `N8N_CALLBACK_TOKEN` (compare `body.callback_token` against `settings.N8N_CALLBACK_TOKEN`)
- **Slack** — HMAC request verification (use `slack_sdk.signature.SignatureVerifier`)

## MCP Server Security

- `X-MCP-API-Key` header required on all `/mcp/rpc` requests in production
- `GET /mcp/info` is unauthenticated (server discovery only)

## Cost Controls

- OpenAI hard cap: $10 (rejects new requests if cost exceeds)
- Billing alerts configured on all providers
- DeepSeek: alert at $5
- Voyage: alert at 150M tokens
- Railway: alert at $10/mo
