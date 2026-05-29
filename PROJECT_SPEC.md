# PROJECT_SPEC.md — IISc Grounded Agentic RAG Platform

## Project Title
**Grounded Agentic RAG Platform for Customer Onboarding**

## One-Line Summary
A multi-tenant SaaS platform where any business can upload their documents and immediately offer their customers a grounded, citation-backed Q&A experience via Web UI, WhatsApp, and Slack — with no hallucinations.

## Problem Statement
Businesses onboarding customers face repeated support queries that are already answered in their manuals, SOPs, and FAQs. Agents waste time answering the same questions. This platform lets businesses upload their knowledge base once and let customers self-serve instantly, with every answer grounded in the actual source document.

## Goals
1. **Any document, any customer** — upload PDF, DOCX, TXT, or web URL; any business vertical
2. **Grounded answers only** — every response cites the source chunk and page number
3. **Multi-channel** — same knowledge base served via Web chat, WhatsApp, and Slack
4. **Multi-tenant** — Tenant A's documents are never visible to Tenant B
5. **Admin control** — each business manages their own documents and users

## MVP Scope

### In Scope
- Tenant registration and onboarding wizard
- Document ingestion: PDF, DOCX, TXT, URL
- Chunking (512 tokens, 50 overlap) + OpenAI embedding + pgvector storage
- Hybrid retrieval: pgvector cosine similarity + tenant isolation
- Grounded answer generation with source citations and follow-up questions
- Admin Web UI: upload, manage documents, manage users
- Chat Web UI: query, view citations, conversation history
- WhatsApp bot via Twilio: query knowledge base from phone
- Slack bot: query via `@mention` in any channel
- JWT authentication with role-based access (super-admin, admin, user)
- RAGAS-based evaluation framework

### Out of Scope
- Autonomous actions (no code execution, no form submissions)
- Real-time document sync from external systems (v2)
- Voice interface (v2)
- Custom LLM fine-tuning (uses OpenAI API only)
- Mobile native app (WhatsApp serves mobile users)

## Success Criteria
| Metric | Target |
|---|---|
| Upload PDF → queryable | < 2 minutes |
| Retrieval@5 | Expected source in top-5 chunks ≥ 80% |
| Citation coverage | ≥ 90% of answers have citations |
| Multi-tenant isolation | 100% — Tenant A cannot see Tenant B's data |
| End-to-end demo | Runs without error on clean docker compose up |
| WhatsApp response time | < 10 seconds |

## Domain
**Customer Onboarding — Any Vertical**
Demo tenants:
- **Company A**: Product manuals (dishwasher, appliance troubleshooting)
- **Company B**: IT helpdesk SOPs
- **Company C**: Industrial equipment maintenance guides

## Team
13 members · Tech Lead M1 · Sprint: 29 May – 3 June 2026

## Tech Decisions (locked — do not change without M1 approval)
| Decision | Choice | Rationale |
|---|---|---|
| RAG engine | n8n | Visual workflow, easy to debug, no code LLM orchestration |
| Vector DB | pgvector | Unified with main Postgres, no extra service |
| Embedding model | text-embedding-3-small | Cost-effective, 1536 dimensions |
| Generation model | gpt-4o-mini | Fast, cheap, sufficient for grounded Q&A |
| Frontend | Next.js 14 | Team familiarity, App Router, TypeScript |
| Bot platform | Twilio (WA) + Slack Bolt | Best-in-class APIs, sandbox support |
