# Admin API

The admin module handles document management, user management, and tenant administration.

**Owner**: M3 · **File**: `backend/app/api/admin.py`

:::{admonition} Implementation Status
:class: warning

All endpoints below are currently **501 stubs**. Route scaffolds exist in `backend/app/api/admin.py` but return `HTTPException(501)`. M3 owns document endpoints; M2 owns user/tenant endpoints. The file validator (`services/file_validator.py`) is implemented and ready to be wired into the upload handler.
:::

## Planned Endpoints

### Documents

| Endpoint | Method | Description |
|:---------|:-------|:------------|
| `/admin/documents` | GET | List all documents for the current tenant |
| `/admin/documents/upload` | POST | Upload a document (PDF/DOCX/TXT/URL) for ingestion |
| `/admin/documents/{id}` | GET | Get document details (metadata, chunk count, status) |
| `/admin/documents/{id}` | DELETE | Delete a document and its chunks |

### Upload Flow (Planned)

:::{admonition} Not Yet Implemented
:class: warning

This flow is the **target design** from `ARCHITECTURE.md`. M3 should implement steps 1–5 in `admin.py`. The file validator (step 2) and n8n client (step 4) are already implemented and ready to use.
:::

1. Admin uploads file via `POST /admin/documents/upload`
2. FastAPI validates: MIME type, magic bytes, file size (≤ 25 MB), tenant quota (≤ 1 GB) — *use `services/file_validator.validate_upload()`*
3. File saved to `/uploads/{tenant_id}/{document_id}.{ext}`
4. `Document` record created with `status=pending`
5. n8n ingestion webhook triggered — *use `services/n8n_client.trigger_ingestion()`*
6. n8n calls back with status (`completed` / `failed`) + chunk count

### Users

| Endpoint | Method | Description |
|:---------|:-------|:------------|
| `/admin/users` | GET | List users in current tenant |
| `/admin/users/{id}` | PATCH | Update user role or status |

### Tenants (super_admin only)

| Endpoint | Method | Description |
|:---------|:-------|:------------|
| `/admin/tenants` | GET | List all tenants |
| `/admin/tenants` | POST | Create a new tenant |
| `/admin/tenants/{id}` | PATCH | Activate/deactivate tenant |
