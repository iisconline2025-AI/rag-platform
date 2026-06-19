# MCP Server

The Model Context Protocol (MCP) server allows external AI clients like Claude Desktop and Cursor to query the RAG platform as a tool.

**Owner**: M2 · **Files**: `backend/app/mcp/server.py`, `backend/app/mcp/tools.py`

## Endpoints

### GET `/mcp/info`

Server discovery endpoint. Returns server name, version, and available tools. **No authentication required.**

**Response** (returns name + description per tool; full `inputSchema` is available via `POST /mcp/rpc` with `tools/list`):
```json
{
  "name": "iisc-rag-platform",
  "version": "1.0.0",
  "protocol": "mcp/1.0",
  "tools": [
    {
      "name": "query_knowledge_base",
      "description": "Ask a question and get a grounded answer with citations"
    },
    {
      "name": "list_documents",
      "description": "List all documents available in a tenant's knowledge base"
    }
  ]
}
```

### POST `/mcp/rpc`

JSON-RPC endpoint for tool execution. **Requires `X-MCP-API-Key` header.**

**Request**:
```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "query_knowledge_base",
    "arguments": {
      "query": "What is the warranty period?",
      "tenant_id": "83d5f2cf-e28a-48fa-8092-367735a99c1d"
    }
  },
  "id": 1
}
```

## Claude Desktop Configuration

Edit `claude_desktop_config.json` (Settings → Developer → Edit Config):

```json
{
  "mcpServers": {
    "iisc-rag-platform": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-fetch",
        "https://<your-railway-backend>/mcp/rpc"
      ],
      "env": {
        "MCP_API_KEY": "<your MCP_API_KEY from .env>"
      }
    }
  }
}
```

Restart Claude Desktop. The tool list should show `query_knowledge_base` and `list_documents`.
