# Project Overview

## What is the IISc RAG Platform?

The **IISc Grounded Agentic RAG Platform** is a multi-tenant SaaS solution that enables businesses to upload their knowledge base (manuals, SOPs, FAQs) and offer instant, citation-backed Q&A to their customers across multiple channels.

## Problem Statement

Businesses onboarding customers face repeated support queries that are already answered in their documentation. Agents waste time answering the same questions. This platform lets businesses upload their knowledge base once and let customers self-serve instantly — with every answer grounded in the actual source document.

## Key Features

### Grounded Answers Only
Every response cites the source document, page number, and exact text chunk. The platform **never hallucinates** — if no relevant information is found, it says "I don't have enough information."

### Multi-Tenant Isolation
Each tenant's documents are completely isolated. Tenant A's documents are never visible to Tenant B. This is enforced at the database level with `WHERE tenant_id = :tenant_id` on every query.

### Multi-Channel Delivery
The same knowledge base is served across:
- **Web Chat** — full UI with citations panel and conversation history
- **WhatsApp** — text answers via Twilio Sandbox
- **MCP** — Claude Desktop / Cursor via JSON-RPC
- **Slack** — `@mention` replies in threads

### Agentic Retrieval
The retrieval pipeline runs as an n8n agent loop with:
- Tool selection (search KB, search ephemeral, ask clarification, web lookup)
- Voyage reranking of retrieved chunks
- Gemini self-check for faithfulness verification
- Automatic retry with a stronger model if faithfulness is below threshold

### Ephemeral Uploads
WhatsApp users can send a PDF and ask questions about it immediately. These chunks are stored in `ephemeral_chunks` with a 1-hour TTL and auto-purged.

## Success Criteria

| Metric | Target |
|:-------|:-------|
| Upload PDF → queryable | < 2 minutes |
| Retrieval@5 | Expected source in top-5 chunks ≥ 80% |
| Citation coverage | ≥ 90% of answers have citations |
| Multi-tenant isolation | 100% — zero cross-tenant leakage |
| End-to-end demo | Runs without error on clean `docker compose up` |
| WhatsApp response time | < 10 seconds |

## Demo Tenants

| Tenant | Domain | Document Types |
|:-------|:-------|:---------------|
| Company A | Consumer electronics | Product manuals, troubleshooting guides |
| Company B | IT helpdesk | SOPs, runbooks |
| Company C | Industrial equipment | Maintenance guides, spec sheets |
