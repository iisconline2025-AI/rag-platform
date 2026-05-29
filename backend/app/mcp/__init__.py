"""MCP (Model Context Protocol) server package.

Exposes the platform's grounded RAG retrieval as MCP tools that any MCP
client (Claude Desktop, Cursor, Continue, etc.) can invoke.

Owner: M3 (chat) + M4 (channels) co-own. Mounted from app.main when
settings.MCP_ENABLED is true.
"""
