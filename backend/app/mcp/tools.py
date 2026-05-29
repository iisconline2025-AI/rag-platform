"""MCP tool registry — maps tool names to async handlers.

Each tool wraps an existing platform capability so MCP clients (Claude
Desktop, Cursor, etc.) can call them.  Add tools by appending to
TOOL_REGISTRY.
"""
from __future__ import annotations
from typing import Any

from app.core.config import settings


async def _tool_query_kb(arguments: dict[str, Any]) -> dict[str, Any]:
    """Forward to the platform's grounded retrieval (mock in dev)."""
    query = arguments.get("query", "")
    tenant_slug = arguments.get("tenant_slug", settings.SEED_TENANT_SLUG)

    if settings.MOCK_N8N:
        return {
            "answer": (
                f"[MOCK MCP] Grounded answer for '{query}' in tenant '{tenant_slug}'. "
                "Set MOCK_N8N=false to call the real n8n retrieval workflow."
            ),
            "sources": [
                {"title": "Sample Doc", "page_number": 1, "score": 0.91}
            ],
            "faithfulness": 0.92,
        }

    # Real path: M3 will resolve tenant_slug → tenant_id via DB lookup.
    # For now the MCP tool is mock-only when MOCK_N8N=false until that wiring
    # lands.  TODO M3: import a get_tenant_id_by_slug() helper and call
    # n8n_client.retrieve(query=query, tenant_id=<uuid>).
    return {
        "answer": "MCP tool not yet wired to live n8n. Set MOCK_N8N=true for demo.",
        "sources": [],
        "faithfulness": 0.0,
    }


async def _tool_list_docs(arguments: dict[str, Any]) -> dict[str, Any]:
    """List documents available in the caller's tenant (mock-safe)."""
    _ = arguments  # reserved for tenant_slug filter when wired by M3
    return {
        "documents": [
            {"id": "00000000-0000-0000-0000-000000000001",
             "title": "Sample Product Manual", "status": "completed", "chunk_count": 42},
        ],
        "note": "MCP demo response. M3 will wire to real /admin/documents.",
    }


TOOL_REGISTRY: dict[str, dict[str, Any]] = {
    "query_knowledge_base": {
        "description": (
            "Query the tenant's knowledge base. Returns a grounded answer with "
            "citations + a faithfulness score."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "User question"},
                "tenant_slug": {"type": "string", "description": "Tenant identifier (e.g. iisc-demo)"},
            },
            "required": ["query"],
        },
        "handler": _tool_query_kb,
    },
    "list_documents": {
        "description": "List documents ingested for the tenant.",
        "input_schema": {
            "type": "object",
            "properties": {
                "tenant_slug": {"type": "string"},
            },
        },
        "handler": _tool_list_docs,
    },
}


async def run_tool(name: str, arguments: dict[str, Any]) -> Any:
    handler = TOOL_REGISTRY[name]["handler"]
    return await handler(arguments)
