# 3-Minute Demo Script — IISc Grounded Agentic RAG Platform

> Demo day. Audience: IISc panel + industry mentors. Goal: prove **grounded**, **multi-channel**, **agentic**.

---

## Pre-flight Checklist (run T-30 min)

- [ ] All Railway services green
- [ ] Vercel build green
- [ ] `MOCK_N8N=false` in Railway
- [ ] `curl https://<api>/health` → `"status":"ok"`
- [ ] Seed tenant has 5 sample PDFs ingested (`evaluation/sample-data/`)
- [ ] Phone has WhatsApp Sandbox joined (`join <sandbox-keyword>`)
- [ ] Laptop has Claude Desktop open with MCP server configured (see section 4)
- [ ] Browser tabs ready: Admin UI, Chat UI, RAGAS eval dashboard

---

## Script (3 min, 4 acts)

### Act 1 — Web Chat with Citations (45 sec)
1. Open Chat UI: `https://app.<domain>/chat`
2. Ask: *"What is the warranty period for the WidgetPro?"*
3. **Point out**: answer cites `[Manual, p.4]`. Click the citation → side panel shows the exact chunk.
4. **Point out**: faithfulness score badge (green, e.g. 0.94). Explain Gemini self-check.

### Act 2 — WhatsApp (45 sec)
1. From phone, WhatsApp message: *"How do I reset the device?"*
2. Reply arrives in <5 sec with citation.
3. Now send a **PDF** in WhatsApp: *"Here is my purchase invoice — when does my warranty expire?"*
4. Bot answers **using the uploaded file** (ephemeral retrieval).
5. **Point out**: this chunk is in `ephemeral_chunks`, auto-purged in 1 hour. Show DB query if time.

### Act 3 — MCP (Claude Desktop) (45 sec)
1. Open Claude Desktop.
2. Type: *"Using the rag-platform tool, what does our manual say about firmware updates?"*
3. Claude calls `query_knowledge_base` tool → returns grounded answer with the same citations.
4. **Point out**: same backend, same grounding, **different channel** (MCP JSON-RPC).

### Act 4 — Evaluation + Cost (45 sec)
1. Open `artifacts/evaluation_results/` — show RAGAS table:
   - Faithfulness: 0.92 avg
   - Answer relevancy: 0.89 avg
   - Context precision: 0.86 avg
2. Show total cost dashboard: **$10 one-time + $5/mo**.
3. Close with: *"Multi-tenant, multi-channel, grounded, agentic, cheap. All in one IISc sprint."*

---

## Claude Desktop MCP Configuration

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

Restart Claude Desktop. Tool list should show `query_knowledge_base` and `list_documents`.

> If `@modelcontextprotocol/server-fetch` is not the right shim for your Claude Desktop version, fall back to: `curl https://<api>/mcp/info` and paste the response into Claude as system context for the demo.

---

## Fallback if Something Breaks

| Failure                  | Fallback                                                                 |
| ------------------------ | ------------------------------------------------------------------------ |
| Voyage API down          | n8n falls through to `openai-text-embedding-3-small` (same 1024-d? NO — re-embed differs; show pre-baked answer) |
| DeepSeek API down        | n8n falls through to `gpt-4o-mini`                                       |
| WhatsApp Sandbox expired | Show pre-recorded video clip (`artifacts/demo_outputs/whatsapp-demo.mp4`)|
| Vercel build red         | Run locally: `cd frontend && npm run dev` + ngrok                        |
| Railway backend cold     | First request will be slow — pre-warm with `curl /health` 30s before demo|

---

## Sample Queries (cherry-picked for reliable demos)

- "What is the warranty period?"        → cites `Manual.pdf` p.4
- "How do I reset the device?"          → cites `Manual.pdf` p.12, `QuickStart.pdf` p.2
- "What firmware versions are supported?" → cites `ReleaseNotes.pdf` p.1
- "Is the device water-resistant?"      → cites `SpecSheet.pdf` p.3

Avoid in demos (known weak answers — fixable post-sprint):
- Tabular data queries from scanned PDFs
- Multi-hop questions spanning 3+ documents
