# API Reference

## Interactive Documentation

The full API is documented in the interactive Swagger UI:

- **Local**: http://localhost:8000/docs
- **Deployed**: https://rag-platform-production.up.railway.app/docs

## OpenAPI Specification

The authoritative API contract is defined in [`specs/openapi.yaml`](https://github.com/iisconline2025-AI/rag-platform/blob/dev/specs/openapi.yaml) (OpenAPI 3.1).

## Endpoint Summary

### Authentication

| Endpoint | Method | Auth | Description |
|:---------|:-------|:-----|:------------|
| `/auth/login` | POST | None | Authenticate and receive JWT |
| `/auth/register` | POST | Admin | Create user in tenant |
| `/auth/me` | GET | Bearer | Current user profile |
| `/auth/logout` | POST | Bearer | Client-side token discard |

### Admin

| Endpoint | Method | Auth | Description |
|:---------|:-------|:-----|:------------|
| `/admin/documents` | GET | Bearer | List tenant documents |
| `/admin/documents/upload` | POST | Admin | Upload document for ingestion |
| `/admin/documents/{id}` | GET | Bearer | Document details |
| `/admin/documents/{id}` | DELETE | Admin | Delete document + chunks |
| `/admin/users` | GET | Admin | List tenant users |
| `/admin/tenants` | GET | Super Admin | List all tenants |

### Chat

| Endpoint | Method | Auth | Description |
|:---------|:-------|:-----|:------------|
| `/chat/query` | POST | Bearer | Submit question → grounded answer |
| `/chat/conversations` | GET | Bearer | List conversations |
| `/chat/conversations/{id}` | GET | Bearer | Conversation messages |
| `/chat/conversations/{id}` | DELETE | Bearer | Delete conversation |

### Webhooks

| Endpoint | Method | Auth | Description |
|:---------|:-------|:-----|:------------|
| `/webhooks/whatsapp` | POST | Twilio Sig | WhatsApp incoming |
| `/webhooks/slack/events` | POST | HMAC | Slack events |
| `/webhooks/n8n/ingestion-status` | POST | Token | n8n callback |

### MCP

| Endpoint | Method | Auth | Description |
|:---------|:-------|:-----|:------------|
| `/mcp/info` | GET | None | Server discovery |
| `/mcp/rpc` | POST | API Key | JSON-RPC tool execution |

### Onboarding

| Endpoint | Method | Auth | Description |
|:---------|:-------|:-----|:------------|
| `/onboarding/register` | POST | None | Self-service tenant registration |
| `/onboarding/check-slug` | GET | None | Check slug availability |

### Health

| Endpoint | Method | Auth | Description |
|:---------|:-------|:-----|:------------|
| `/health` | GET | None | Service health + DB status |
| `/` | GET | None | API info |

## Authentication

All protected endpoints use JWT Bearer tokens:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

Obtain a token via `POST /auth/login`. Tokens expire after 24 hours.

## Error Responses

All errors follow a consistent format:

```json
{
  "detail": "Human-readable error message"
}
```

| Status | Meaning |
|:-------|:--------|
| `400` | Bad request (validation error) |
| `401` | Not authenticated / invalid token |
| `403` | Insufficient permissions |
| `404` | Resource not found |
| `409` | Conflict (e.g., duplicate email) |
| `429` | Rate limit exceeded |
| `500` | Internal server error |
| `501` | Not implemented (stub endpoint) |
