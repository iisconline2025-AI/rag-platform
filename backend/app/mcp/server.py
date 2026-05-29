"""MCP server endpoints — exposes /chat/query and /admin/documents as MCP tools.

This is a thin HTTP shim that speaks the MCP JSON-RPC dialect so Claude
Desktop and other MCP clients can call the platform's grounded retrieval.

NOTE: Spec is intentionally minimal for the IISc demo. Full MCP spec at
https://modelcontextprotocol.io/specification — extend as needed.

Auth: shared secret via `X-MCP-API-Key` header (settings.MCP_API_KEY).
"""
from __future__ import annotations

from fastapi import APIRouter, Header, HTTPException
from pydantic import BaseModel
from typing import Any, Optional

from app.core.config import settings
from app.mcp.tools import TOOL_REGISTRY, run_tool

mcp_router = APIRouter()


# ── Auth dependency ─────────────────────────────────────────────────────
def _verify_api_key(x_mcp_api_key: Optional[str] = Header(default=None)) -> None:
    if not settings.MCP_API_KEY or settings.MCP_API_KEY == "change-me-mcp-shared-secret":
        # Allow open access in dev; reject in production.
        if settings.APP_ENV == "production":
            raise HTTPException(401, "MCP_API_KEY not configured")
        return
    if x_mcp_api_key != settings.MCP_API_KEY:
        raise HTTPException(401, "Invalid X-MCP-API-Key header")


# ── MCP JSON-RPC shapes (subset) ────────────────────────────────────────
class MCPRequest(BaseModel):
    jsonrpc: str = "2.0"
    id: int | str
    method: str
    params: dict[str, Any] = {}


class MCPResponse(BaseModel):
    jsonrpc: str = "2.0"
    id: int | str
    result: dict[str, Any] | None = None
    error: dict[str, Any] | None = None


@mcp_router.get("/info", summary="MCP server metadata (no auth)")
async def mcp_info() -> dict[str, Any]:
    """Returns capability info for MCP discovery."""
    return {
        "name": "iisc-rag-platform",
        "version": "1.0.0",
        "protocol": "mcp/1.0",
        "tools": [
            {"name": name, "description": meta["description"]}
            for name, meta in TOOL_REGISTRY.items()
        ],
    }


@mcp_router.post("/rpc", summary="MCP JSON-RPC endpoint")
async def mcp_rpc(req: MCPRequest, _: None = None) -> MCPResponse:
    """Handle MCP method calls. Currently supports: tools/list, tools/call."""
    _verify_api_key()  # called explicitly so dependency override stays simple

    if req.method == "tools/list":
        return MCPResponse(
            id=req.id,
            result={
                "tools": [
                    {
                        "name": name,
                        "description": meta["description"],
                        "inputSchema": meta["input_schema"],
                    }
                    for name, meta in TOOL_REGISTRY.items()
                ]
            },
        )

    if req.method == "tools/call":
        name = req.params.get("name")
        args = req.params.get("arguments", {})
        if name not in TOOL_REGISTRY:
            return MCPResponse(id=req.id, error={"code": -32601, "message": f"Unknown tool: {name}"})
        try:
            output = await run_tool(name, args)
            return MCPResponse(
                id=req.id,
                result={"content": [{"type": "text", "text": str(output)}]},
            )
        except Exception as e:  # noqa: BLE001 — surface to client
            return MCPResponse(id=req.id, error={"code": -32000, "message": str(e)})

    return MCPResponse(id=req.id, error={"code": -32601, "message": f"Unknown method: {req.method}"})
