# GitHub Copilot — Repo-Wide Instructions

> **IISc Grounded Agentic RAG Platform** — multi-tenant customer onboarding via Web UI / WhatsApp.
> Read [CLAUDE.md](../CLAUDE.md), [ARCHITECTURE.md](../ARCHITECTURE.md), and your [module spec](../specs/) before generating code.

## Locked Stack (do not substitute without M1 approval)
| Layer | Choice |
|---|---|
| API Gateway | Python 3.11 · FastAPI · Uvicorn |
| RAG Engine  | n8n self-hosted (workflows as JSON in repo) |
| Database    | PostgreSQL 15 + pgvector (1024-dim, HNSW) on **Neon** |
| Embeddings  | Voyage `voyage-4-large` (1024-d, free 200M tokens) |
| Rerank      | Voyage `rerank-2.5` |
| Generation  | DeepSeek V4 Flash (primary) → DeepSeek V4 Pro (fallback) |
| Self-check  | Gemini 3.5 Flash (faithfulness 0–1) |
| OCR         | OpenAI `gpt-4o` vision (scanned PDFs only) |
| Frontend    | Next.js 14 · TypeScript · TailwindCSS · Vercel |
| Auth        | JWT (python-jose) + bcrypt — **no Redis** |
| Rate-limit  | slowapi (in-process) |
| Bots        | Twilio Programmable Messaging (WhatsApp) |

## Hard Rules
1. **FastAPI is a thin gateway.** ALL RAG logic (parse, chunk, embed, retrieve, generate) lives in n8n. Do NOT add LLM/embedding calls to FastAPI.
2. **Every answer must cite a source chunk.** No ungrounded answers.
3. **Multi-tenant isolation is a hard gate.** Every DB query MUST include `WHERE tenant_id = :tenant_id`.
4. **Contract changes go through M1.** Edit `specs/openapi.yaml` only via PR reviewed by M1.
5. **No secrets in code.** All keys in `.env` (gitignored). Use `settings` from `app.core.config`.
6. **No `print()`** in production code — use Python `logging`.
7. **Mock-first.** Build against `MOCK_N8N=true` so frontend and bots don't block on RAG engine.
8. **PRs target `dev`**, then M1 merges to `main` after E2E smoke test.

## Module Ownership Map
Each module has a scoped Copilot instruction file in [.github/instructions/](instructions/) that activates automatically when you edit that module's files. Each one links back to the full spec.

| Module | Role | Owner | Spec | Copilot scope |
|---|---|---|---|---|
| **M1**  | Integration / Tech Lead     | 🔓 OPEN              | [MODULE_SPEC_M1.md](../specs/MODULE_SPEC_M1.md)   | [M1.instructions.md](instructions/M1.instructions.md) |
| **M2**  | Auth & Core                 | Keshav Kumar         | [MODULE_SPEC_M2.md](../specs/MODULE_SPEC_M2.md)   | [M2.instructions.md](instructions/M2.instructions.md) |
| **M3**  | Document & Chat APIs        | Karthic V            | [MODULE_SPEC_M3.md](../specs/MODULE_SPEC_M3.md)   | [M3.instructions.md](instructions/M3.instructions.md) |
| **M4**  | Webhooks (WA + Slack)       | Tushar Srivastava    | [MODULE_SPEC_M4.md](../specs/MODULE_SPEC_M4.md)   | [M4.instructions.md](instructions/M4.instructions.md) |
| **M5**  | n8n Ingestion Pipeline      | Kumari Priyanka      | [MODULE_SPEC_M5.md](../specs/MODULE_SPEC_M5.md)   | [M5.instructions.md](instructions/M5.instructions.md) |
| **M6**  | n8n Retrieval (Agentic)     | Shreya Shrivastava   | [MODULE_SPEC_M6.md](../specs/MODULE_SPEC_M6.md)   | [M6.instructions.md](instructions/M6.instructions.md) |
| **M7**  | Infrastructure & DB         | 🔓 OPEN (P0 blocker) | [MODULE_SPEC_M7.md](../specs/MODULE_SPEC_M7.md)   | [M7.instructions.md](instructions/M7.instructions.md) |
| **M8**  | Frontend: Admin Portal      | Ritika Gupta         | [MODULE_SPEC_M8.md](../specs/MODULE_SPEC_M8.md)   | [M8.instructions.md](instructions/M8.instructions.md) |
| **M9**  | Frontend: Chat Portal       | Joy Das              | [MODULE_SPEC_M9.md](../specs/MODULE_SPEC_M9.md)   | [M9.instructions.md](instructions/M9.instructions.md) |
| **M10** | Evaluation & Testing        | Yashas H M           | [MODULE_SPEC_M10.md](../specs/MODULE_SPEC_M10.md) | [M10.instructions.md](instructions/M10.instructions.md) |
| **M11** | Documentation & Demo        | 🔓 OPEN              | [MODULE_SPEC_M11.md](../specs/MODULE_SPEC_M11.md) | [M11.instructions.md](instructions/M11.instructions.md) |
| **M12** | WhatsApp Bot Specialist     | Tushar Srivastava    | [MODULE_SPEC_M12.md](../specs/MODULE_SPEC_M12.md) | [M12.instructions.md](instructions/M12.instructions.md) |
| **M13** | Customer Onboarding         | 🔓 OPEN              | [MODULE_SPEC_M13.md](../specs/MODULE_SPEC_M13.md) | [M13.instructions.md](instructions/M13.instructions.md) |

## Code Style
- **Python**: Black, isort, type hints, no `print()`.
- **TypeScript**: ESLint + Prettier, strict mode.
- **Commits**: `type(scope): message` — feat / fix / docs / test / chore.

## Don't
- Put LLM or embedding calls in FastAPI (that's n8n).
- Commit `.env` or any secret.
- Push directly to `main`.
- Generate ungrounded answers.
- Skip `tenant_id` filter in DB queries.
