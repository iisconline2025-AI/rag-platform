# Appends "Skills Required" + "Detailed Step-by-Step Plan" + "Learning Resources"
# to each MODULE_SPEC_M*.md file. Idempotent: skips if marker already present.
# Run once: pwsh ./scripts/append_spec_skills.ps1

$ErrorActionPreference = "Stop"
$specsDir = Join-Path (Join-Path $PSScriptRoot "..") "specs"
$marker   = "<!-- AUTO-APPENDED:SKILLS-V1 -->"

# ─────────────────────────────────────────────────────────────────────────
# Per-module skills + step-by-step instructions
# ─────────────────────────────────────────────────────────────────────────
$blocks = @{

"M1" = @"
## Skills Required
- **Must-have:** Git/GitHub (PRs, branching, merge conflicts), reading OpenAPI/YAML, writing Markdown docs, basic Docker, REST API contracts.
- **Nice-to-have:** GitHub Actions CI, Mermaid diagrams, Postman/Insomnia, semantic-release.
- **Soft skills:** Daily standup facilitation, unblocking teammates, scope guardrails.

## Detailed Step-by-Step Plan
### Day 1 — Repo & Contract Lock
1. Verify `main` builds clean: ``docker compose config`` and ``cd backend && python -m compileall app``.
2. Tag the lock-in commit: ``git tag v0.1-day1 && git push --tags``.
3. Create GitHub Project board with columns: Backlog / In-Progress / Review / Done.
4. Add issue templates: ``.github/ISSUE_TEMPLATE/bug.md``, ``feature.md``.
5. Open one tracking issue per module (M2…M13) and assign owner.
6. Post Slack message with: repo URL, branch policy, ``MODULE_SPEC_M*.md`` link per person, daily standup time (15-min, 10:00 IST).

### Day 2-3 — Active Gatekeeping
7. Review every PR within 2 hours (sprint-mode SLA). Run smoke test before approving.
8. Maintain ``CHANGELOG.md`` — one bullet per merged PR.
9. Watch for contract drift: if anyone edits ``specs/openapi.yaml`` outside of you, revert and discuss.

### Day 4-5 — Integration
10. Coordinate the ``MOCK_N8N=false`` cutover: announce 1-hour freeze, M3+M5+M6 in same call.
11. Run end-to-end smoke: upload PDF → verify chunks in DB → query via web UI → verify citation → query via WhatsApp.
12. File bugs found as P0/P1/P2 issues; reassign to module owner.

### Day 6 — Demo
13. Record 3-min demo video per ``docs/DEMO.md``.
14. Push final ``v1.0-demo`` tag. Run ``git log --oneline v0.1-day1..HEAD | wc -l`` for retro stats.

## Learning Resources
- OpenAPI 3.0 spec: https://swagger.io/specification/
- Conventional commits: https://www.conventionalcommits.org/
- GitHub flow: https://docs.github.com/en/get-started/quickstart/github-flow
"@

"M2" = @"
## Skills Required
- **Must-have:** Python 3.11, FastAPI, Pydantic v2, SQLAlchemy 2.0 ORM, Alembic migrations, JWT (python-jose), bcrypt, pytest.
- **Nice-to-have:** Async SQLAlchemy, dependency-injection patterns, OAuth2 password flow, slowapi rate-limiting.
- **Soft skills:** Defensive coding (validate every input), security mindset.

## Detailed Step-by-Step Plan
### Day 1 — Environment
1. ``cd backend && python -m venv .venv && .venv\Scripts\activate``
2. ``pip install -r requirements.txt``
3. Confirm ``uvicorn app.main:app --reload`` boots (errors expected before DB is up — that's OK).
4. Create branch ``feat/auth`` from ``main``.

### Day 2 — Alembic + Models
5. Initialize Alembic: ``cd backend && alembic init alembic`` (skip if folder exists).
6. Configure ``alembic.ini`` to read ``DATABASE_URL`` from env: in ``alembic/env.py`` import ``settings`` and set ``config.set_main_option('sqlalchemy.url', settings.DATABASE_URL)``.
7. Import ``app.models.models`` in ``alembic/env.py`` and set ``target_metadata = Base.metadata``.
8. Generate initial migration: ``alembic revision --autogenerate -m "initial schema"``.
9. Review the generated SQL in ``alembic/versions/*.py`` — confirm ``vector(1024)``, HNSW indexes, all 9 tables present.
10. Apply: ``alembic upgrade head``. Verify in Neon console all tables exist.

### Day 3 — Auth + Seed
11. Implement ``app/core/security.py`` helpers: ``hash_password``, ``verify_password``, ``create_access_token``, ``decode_access_token``.
12. Implement ``app/core/dependencies.py``: ``get_current_user``, ``require_role(role)``.
13. Wire ``app/api/auth.py`` endpoints: ``POST /login``, ``POST /register``, ``GET /me``, ``POST /logout``.
14. Build ``scripts/seed_admin.py``: creates 1 tenant + 1 super_admin user from env vars; idempotent.
15. Run end-to-end: ``python -m scripts.seed_admin`` → ``curl -X POST /auth/login`` → save JWT → ``curl -H "Authorization: Bearer $TOKEN" /auth/me``.

### Day 4-5 — Tests + Hardening
16. ``tests/test_auth.py``: login success, login wrong password (401), expired token (401), valid /me, role guard.
17. Add slowapi rate-limit to ``/auth/login`` (5/min per IP).
18. Run ``pytest -v`` → target 90 %+ coverage on auth module.

### Day 6 — Polish
19. Add OpenAPI tags + examples so Swagger UI is presentable for demo.

## Learning Resources
- FastAPI security tutorial: https://fastapi.tiangolo.com/tutorial/security/
- SQLAlchemy 2.0 ORM: https://docs.sqlalchemy.org/en/20/orm/quickstart.html
- Alembic autogenerate caveats: https://alembic.sqlalchemy.org/en/latest/autogenerate.html
"@

"M3" = @"
## Skills Required
- **Must-have:** FastAPI, async Python, httpx, file upload (UploadFile, multipart), Pydantic v2, environment-driven config.
- **Nice-to-have:** Streaming responses, background tasks, n8n webhook conventions.
- **Soft skills:** Mock-first development (build against fake n8n so frontend isn't blocked).

## Detailed Step-by-Step Plan
### Day 1 — Mock-First
1. Branch ``feat/chat-api`` from ``main``.
2. Read ``specs/openapi.yaml`` sections for ``POST /chat/query`` and ``POST /admin/documents/upload``.
3. Confirm ``settings.MOCK_N8N = true`` returns a hardcoded plausible response in ``services/n8n_client.py``.

### Day 2 — Document Upload
4. Implement ``POST /admin/documents/upload`` (multipart): accept file → call ``services/file_validator.validate_upload`` → save to ``UPLOAD_DIR`` with UUID name → INSERT row into ``documents`` with status=``pending`` → call ``n8n_client.ingest()`` → return document ID.
5. Implement ``GET /admin/documents`` — paginated list filtered by ``tenant_id``.
6. Implement ``DELETE /admin/documents/{id}`` — soft-delete + remove chunks.
7. Implement ``POST /admin/documents/url`` — accept JSON ``{url, title}``; same flow but pass URL to n8n instead of file.

### Day 3 — Chat Endpoint
8. Implement ``POST /chat/query``: validate JWT → load last 5 messages from ``chat_messages`` for conversation_id → call ``n8n_client.retrieve(query, tenant_id, history)`` → INSERT both user + assistant messages → return ``{answer, sources, faithfulness, requires_clarification, follow_up_questions}``.
9. Implement ``POST /chat/conversations`` (create new) and ``GET /chat/conversations`` (list).

### Day 4 — Ingestion Callback
10. Implement ``POST /webhooks/ingestion-status`` — guard with ``X-Callback-Token`` header == ``settings.N8N_CALLBACK_TOKEN`` → UPDATE ``documents`` set status, page_count, chunk_count.

### Day 5 — MCP Hook
11. Coordinate with MCP tools (``backend/app/mcp/tools.py``): replace TODO with real tenant_slug → tenant_id DB lookup, then call ``n8n_client.retrieve``.

### Day 6 — Tests
12. ``tests/test_chat.py``: query returns sources, conversation history persisted, tenant isolation (user A cannot read user B's docs).

## Learning Resources
- FastAPI file uploads: https://fastapi.tiangolo.com/tutorial/request-files/
- httpx async: https://www.python-httpx.org/async/
"@

"M4" = @"
## Skills Required
- **Must-have:** FastAPI, Twilio Programmable Messaging API, TwiML, HMAC signature validation, Slack Events API + Bolt SDK, ngrok for local webhook testing.
- **Nice-to-have:** Async background tasks, retry/backoff patterns.

## Detailed Step-by-Step Plan
### Day 1 — Setup
1. Branch ``feat/webhooks``.
2. Create Twilio account, activate WhatsApp Sandbox (https://console.twilio.com → Messaging → Try it out → WhatsApp), join sandbox from your phone (``join <code>`` to the sandbox number).
3. Install ngrok: ``choco install ngrok``; ``ngrok http 8000`` → copy https URL.
4. In Twilio console set sandbox ``When a message comes in`` to ``https://<ngrok>.ngrok-free.app/webhooks/whatsapp``.

### Day 2 — WhatsApp Webhook (text only)
5. Implement ``POST /webhooks/whatsapp`` to accept ``application/x-www-form-urlencoded`` (Twilio sends ``From``, ``Body``, ``MediaUrl0``, etc.).
6. Validate Twilio signature using ``twilio.request_validator.RequestValidator`` and ``settings.TWILIO_AUTH_TOKEN`` (skip if ``settings.DEBUG``).
7. Look up tenant by ``From`` phone in ``whatsapp_tenant_map`` table; reject with TwiML error if not mapped.
8. Call ``services/n8n_client.retrieve(Body, tenant_id, history=[])`` → wrap answer in TwiML ``<Message>`` and return.
9. Test: send WhatsApp message → see mock answer reply.

### Day 3 — WhatsApp Ephemeral Upload
10. When ``MediaUrl0`` is present, download with ``httpx`` (use Twilio basic-auth: account_sid + auth_token).
11. Run ``services/file_validator.validate_upload(content, mime)`` against 10 MB cap and MIME allowlist.
12. Save to ``/tmp/<uuid>.<ext>``.
13. POST to ``settings.N8N_EPHEMERAL_INGEST_WEBHOOK_URL`` with ``{tenant_id, conversation_id, file_path, ttl_minutes: 60}``.
14. Reply with TwiML: ``"Got it — I've indexed your file. Ask me anything about it for the next hour."``

### Day 4 — Ingestion Callback
15. Implement ``POST /webhooks/ingestion-status`` (co-owned with M3) — same handler; verify ``X-Callback-Token``.

### Day 5 — Slack (Stretch)
16. ``app/bots/slack.py``: implement ``POST /webhooks/slack/events``; verify ``X-Slack-Signature``; handle ``app_mention`` event → call retrieve → ``chat.postMessage`` reply.

### Day 6 — Tests
17. ``tests/test_webhooks.py``: mock Twilio request, assert TwiML response shape; test signature rejection (403).

## Learning Resources
- Twilio WhatsApp Quickstart: https://www.twilio.com/docs/whatsapp/quickstart/python
- Twilio request validation: https://www.twilio.com/docs/usage/webhooks/webhooks-security
- Slack Bolt for Python: https://slack.dev/bolt-python/concepts
"@

"M5" = @"
## Skills Required
- **Must-have:** n8n (self-hosted), JSON workflow editing, HTTP Request node, Function (JS) node, Postgres node, webhook triggers, Voyage AI embeddings API, basic PDF parsing.
- **Nice-to-have:** OCR with OpenAI gpt-4o vision, recursive text splitting, n8n credentials management.

## Detailed Step-by-Step Plan
### Day 1 — n8n Up & Running
1. Coordinate with M7 to confirm n8n on Railway is reachable. Local fallback: ``docker compose up n8n`` and open http://localhost:5678.
2. Import ``n8n-workflows/ingestion-pipeline.json`` → Workflows → Import from file.
3. Add credentials:
   - **Postgres** → host/user/pass from ``DATABASE_URL`` (Neon).
   - **HTTP Header Auth** (call it ``VoyageAuth``) → ``Authorization: Bearer <VOYAGE_API_KEY>``.
   - **HTTP Header Auth** (``OpenAIAuth``) → for OCR fallback.

### Day 2 — Wire Extraction
4. Webhook node: path ``/ingest``, method POST, response mode ``Last Node``. Note the production URL — give to M3.
5. Function node "Extract Text": if source_type=``pdf`` use ``pdf-parse`` (n8n built-in), if scanned/image use OpenAI vision (HTTP Request to ``https://api.openai.com/v1/chat/completions`` with image_url payload).
6. Test: trigger webhook with ``{document_id, tenant_id, file_path, source_type:"pdf", title}`` → confirm text extracted.

### Day 3 — Chunk + Embed
7. Function node "Chunk": split text into 512-token chunks with 50-token overlap. Output array of ``{chunk_index, text, page_number}``.
8. HTTP Request node "Voyage Embed": POST ``https://api.voyageai.com/v1/embeddings`` with ``{input: [chunk_texts], model: "voyage-4-large", input_type: "document"}``. Returns 1024-dim vectors.
9. Function node "Zip": combine chunks + embeddings into rows.

### Day 4 — Store + Callback
10. Postgres node "Insert Chunks": INSERT INTO ``document_chunks (document_id, tenant_id, chunk_index, text, page_number, embedding)`` VALUES …
11. HTTP Request node "Callback": POST ``{settings.API_BASE}/webhooks/ingestion-status`` with header ``X-Callback-Token: {{ $env.N8N_CALLBACK_TOKEN }}`` and body ``{document_id, status:"completed", chunk_count, page_count}``.
12. On error branch: callback with status=``failed`` + error_message.

### Day 5 — Ephemeral Variant
13. Open ``n8n-workflows/ingest-ephemeral.json``; same flow but INSERT into ``ephemeral_chunks`` with ``expires_at = NOW() + 1 hour`` and ``conversation_id`` from payload.

### Day 6 — Export + Document
14. ``Workflow → Download`` → overwrite the JSON files in ``n8n-workflows/`` → commit. Add screenshot to ``docs/n8n-setup.md``.

## Learning Resources
- n8n docs: https://docs.n8n.io/
- Voyage AI embeddings: https://docs.voyageai.com/docs/embeddings
- Token chunking: https://github.com/openai/tiktoken
"@

"M6" = @"
## Skills Required
- **Must-have:** n8n LangChain nodes (``@n8n/n8n-nodes-langchain.agent``), tool-calling agents, Postgres + pgvector kNN queries, Voyage rerank API, Google Gemini API, DeepSeek API (OpenAI-compatible).
- **Nice-to-have:** Prompt engineering for grounded answers, faithfulness scoring, fallback chains.

## Detailed Step-by-Step Plan
### Day 1 — Import & Credentials
1. Import ``n8n-workflows/retrieval-pipeline.json``.
2. Add credentials: ``DeepSeekAuth`` (Bearer DEEPSEEK_API_KEY, base URL ``https://api.deepseek.com``), ``GeminiAuth``, ``VoyageAuth`` (reuse M5's).

### Day 2 — Query Embed + Retrieval Tool
3. Webhook ``/retrieve`` POST → receives ``{query, tenant_id, conversation_history, max_chunks}``.
4. HTTP "Embed Query": Voyage embeddings with ``input_type: "query"``.
5. Postgres "Search KB": ``SELECT chunk_id, document_id, text, page_number, 1 - (embedding <=> $1) AS score FROM document_chunks WHERE tenant_id = $2 ORDER BY embedding <=> $1 LIMIT 20``.
6. Postgres "Search Ephemeral": same against ``ephemeral_chunks`` filtered by ``conversation_id`` and ``expires_at > NOW()``.

### Day 3 — Rerank + Agent
7. HTTP "Voyage Rerank": POST ``https://api.voyageai.com/v1/rerank`` ``{query, documents:[chunk_texts], model: "rerank-2.5", top_k: 5}``.
8. LangChain Agent node:
   - LLM: DeepSeek V4 Flash (HTTP creds, model=``deepseek-chat``).
   - System prompt: "You are a grounded assistant. Cite sources as [doc_title, p.X]. If chunks don't answer, set requires_clarification=true."
   - Tools: ``search_kb``, ``search_ephemeral``, ``ask_clarifying_question``, ``web_lookup`` (stretch).

### Day 4 — Self-Check Loop
9. HTTP "Gemini Faithfulness": POST ``https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`` with prompt scoring (0-1) whether answer is supported by chunks.
10. IF node ``faithfulness < 0.7`` → branch to DeepSeek V4 Pro retry (model=``deepseek-reasoner``) with stricter prompt.

### Day 5 — Output Contract
11. Function "Format Response": emit JSON ``{answer, sources:[{document_id, title, chunk_text, page_number, score}], faithfulness, requires_clarification, follow_up_questions:[3], metadata:{model, retrieval_time_ms, chunks_retrieved}}``.
12. Respond to Webhook node.

### Day 6 — Test + Export
13. Manually trigger with sample queries. Verify citation accuracy. Export workflow → overwrite JSON → commit.

## Learning Resources
- n8n AI Agent node: https://docs.n8n.io/integrations/builtin/cluster-nodes/root-nodes/n8n-nodes-langchain.agent/
- DeepSeek API: https://api-docs.deepseek.com/
- Gemini API: https://ai.google.dev/gemini-api/docs
- pgvector kNN: https://github.com/pgvector/pgvector#querying
"@

"M7" = @"
## Skills Required
- **Must-have:** Docker + docker-compose, PostgreSQL, pgvector extension, Neon (serverless Postgres), Railway (PaaS) or Render, secret/env management, cron scheduling.
- **Nice-to-have:** Bash, GitHub Actions, observability (Grafana, Sentry).
- **⚠ CRITICAL PATH:** Your Day-1 output unblocks M2, M5, M6. Treat as P0.

## Detailed Step-by-Step Plan
### Day 1 — Neon DB (1-2 hours, P0)
1. Sign up at https://console.neon.tech (free tier: 10 GB).
2. Create project ``rag-platform``, region ``aws-ap-south-1`` (Mumbai).
3. In SQL Editor run: ``CREATE EXTENSION IF NOT EXISTS vector;`` then paste full ``database/init.sql`` content. Verify all tables + HNSW indexes created.
4. Copy connection string (pooled): ``postgres://user:pass@ep-xxx.neon.tech/neondb?sslmode=require``.
5. Post in #infra Slack channel: ``DATABASE_URL=...`` (use a secret share, not plaintext).

### Day 1 (cont.) — n8n on Railway (2 hours)
6. Sign up at https://railway.app. New project → Deploy from template → "n8n".
7. Set env vars: ``N8N_BASIC_AUTH_ACTIVE=true``, ``N8N_BASIC_AUTH_USER``, ``N8N_BASIC_AUTH_PASSWORD``, ``DB_TYPE=postgresdb``, ``DB_POSTGRESDB_HOST/PORT/USER/PASSWORD/DATABASE`` pointing to a SEPARATE Neon branch ``n8n``.
8. Generate public URL; share with M5 + M6.

### Day 2 — Backend on Railway
9. New service → Deploy from GitHub repo → root ``backend/``. Auto-detects Dockerfile.
10. Set all env vars from ``.env`` (DATABASE_URL, VOYAGE_API_KEY, DEEPSEEK_API_KEY, GEMINI_API_KEY, OPENAI_API_KEY, TWILIO_*, JWT_SECRET, N8N_*_WEBHOOK_URL, MOCK_N8N=true initially).
11. Add ``railway.json`` with start command ``alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port $PORT``.
12. Verify ``/health`` returns 200.

### Day 3 — Frontend on Vercel
13. ``cd frontend && vercel --prod`` (link to GitHub repo).
14. Set ``NEXT_PUBLIC_API_BASE_URL`` to Railway backend URL.

### Day 4 — Cron + Backups
15. Add Railway Cron service: command ``python -m scripts.cleanup_ephemeral``, schedule ``0 * * * *`` (hourly).
16. Enable Neon point-in-time-restore (default 7 days).

### Day 5 — Monitoring
17. Wire Sentry (free tier) DSN into backend ``app/main.py``.
18. Set up uptime check on ``/health`` via UptimeRobot.

### Day 6 — Cutover Day
19. Coordinate with M1: set ``MOCK_N8N=false`` on Railway, restart service, run smoke test.

## Learning Resources
- Neon docs: https://neon.tech/docs
- Railway docs: https://docs.railway.app
- pgvector: https://github.com/pgvector/pgvector
- Vercel Next.js: https://vercel.com/docs/frameworks/nextjs
"@

"M8" = @"
## Skills Required
- **Must-have:** Next.js 14 App Router, TypeScript, TailwindCSS, React hooks, JWT in localStorage/cookies, file upload UX, drag-and-drop.
- **Nice-to-have:** SWR or TanStack Query, shadcn/ui, optimistic updates, openapi-typescript codegen.

## Detailed Step-by-Step Plan
### Day 1 — Scaffold
1. ``cd frontend && npm install``. Confirm ``npm run dev`` opens http://localhost:3000.
2. Generate API client: ``npx openapi-typescript ../specs/openapi.yaml -o src/types/api.ts``.
3. Branch ``feat/admin-ui``.
4. Create ``src/lib/api.ts``: ``fetch`` wrapper that auto-attaches ``Bearer ${localStorage.token}``.

### Day 2 — Auth Pages
5. ``app/login/page.tsx``: email+password form → POST /auth/login → store token → redirect /admin.
6. ``app/admin/layout.tsx``: sidebar (Documents, Users, Tenants, Settings) + AuthGuard HOC redirecting to /login if no token.

### Day 3 — Document Upload + List
7. ``app/admin/documents/page.tsx``: drag-drop zone (use ``react-dropzone``) → multipart POST /admin/documents/upload → optimistic row insert.
8. Status badges: pending (gray) / processing (yellow spinner) / completed (green) / failed (red). Poll every 5 sec for pending rows.
9. Add second tab "Add by URL" → JSON POST /admin/documents/url.

### Day 4 — Users + Tenants Mgmt
10. ``app/admin/users/page.tsx``: table of users, role dropdown (super_admin/admin/user), invite-user modal.
11. ``app/admin/tenants/page.tsx``: list tenants, create/edit modal, show usage (storage_used_bytes / 1 GB cap).

### Day 5 — Settings + Polish
12. ``app/admin/settings/page.tsx``: API keys section (masked, copy button), rate-limit display.
13. Dark mode toggle (TailwindCSS ``dark:`` classes + ``next-themes``).
14. Mobile responsive review.

### Day 6 — Deploy + Tests
15. Push to ``main`` → Vercel auto-deploys (M7 set this up).
16. Cypress or Playwright smoke test: login → upload → see document in list.

## Learning Resources
- Next.js App Router: https://nextjs.org/docs/app
- TailwindCSS: https://tailwindcss.com/docs/installation
- openapi-typescript: https://github.com/drwpow/openapi-typescript
- shadcn/ui: https://ui.shadcn.com
"@

"M9" = @"
## Skills Required
- **Must-have:** Next.js 14, TypeScript, TailwindCSS, React state mgmt, Markdown rendering (``react-markdown``), streaming/SSE basics.
- **Nice-to-have:** ``@uiw/react-md-editor``, syntax highlighting (``rehype-highlight``), zustand state, mobile-first design.

## Detailed Step-by-Step Plan
### Day 1 — Wireframe
1. Branch ``feat/chat-ui``. Sketch layout: left sidebar (conversation list + "New chat" button) / center chat area / right collapsible "Sources" drawer.
2. Install ``react-markdown`` ``rehype-highlight`` ``rehype-raw``.

### Day 2 — Message Components
3. ``components/chat/Message.tsx``: user bubble (right, blue) vs assistant bubble (left, surface). Render markdown with code-block syntax highlighting.
4. ``components/chat/CitationCard.tsx``: shows document title, page number, snippet, score. Click → opens Sources drawer.
5. ``components/chat/FaithfulnessBadge.tsx``: green (≥0.85) / amber (0.7-0.85) / red (<0.7); tooltip explains "self-check score".

### Day 3 — Chat Page
6. ``app/chat/[conversationId]/page.tsx``: load history GET /chat/conversations/{id}/messages, render message list, autoscroll bottom.
7. Input box at bottom: textarea + Send button (Cmd+Enter). On submit → POST /chat/query with conversation_id → append both messages.
8. Show typing indicator (3 bouncing dots) while waiting.

### Day 4 — Follow-ups + Clarifications
9. Render ``follow_up_questions`` as 3 clickable chips below assistant message; click sends as next query.
10. If ``requires_clarification=true``, render a warning banner above the answer and highlight the badge red.

### Day 5 — Sidebar + Polish
11. ``components/chat/Sidebar.tsx``: list conversations (GET /chat/conversations), highlight active, "New chat" → POST /chat/conversations → redirect.
12. Conversation title auto-generated from first user message (truncate 40 chars).
13. Dark mode default; light theme toggle.

### Day 6 — Mobile + Demo Prep
14. Test on iPhone-width (375 px). Drawer becomes full-screen on mobile.
15. Pre-seed 3 demo conversations for screenshots.

## Learning Resources
- react-markdown: https://github.com/remarkjs/react-markdown
- TailwindCSS chat UI patterns: https://tailwindui.com/components/application-ui/messaging
- Zustand: https://zustand-demo.pmnd.rs/
"@

"M10" = @"
## Skills Required
- **Must-have:** Python, pytest, RAGAS framework, Pandas, prompt-engineering judgment, dataset curation.
- **Nice-to-have:** Locust or k6 for load testing, GitHub Actions for CI eval, Jupyter notebooks for analysis.

## Detailed Step-by-Step Plan
### Day 1 — Sample Data
1. Collect 5-10 sample PDFs (manuals, FAQs, SOPs) → drop in ``evaluation/sample-data/`` (≤ 5 MB each).
2. Create folder ``evaluation/qa-set/`` with ``ground_truth.jsonl`` — start writing 30 entries.

### Day 2 — Q&A Curation (30 pairs)
3. For each PDF, write 3 questions of 3 types: factoid, multi-hop reasoning, "no answer in docs" (negative). JSON shape: ``{question, expected_answer, expected_source_doc, expected_page, type}``.

### Day 3 — RAGAS Harness
4. ``pip install ragas pandas pytest``.
5. Create ``evaluation/run_eval.py``:
   - For each Q&A: POST /chat/query → collect ``answer + sources``.
   - Feed to RAGAS metrics: ``faithfulness``, ``answer_relevancy``, ``context_precision``, ``context_recall``.
   - Save results CSV to ``evaluation/results/run-{timestamp}.csv``.

### Day 4 — Baseline + Negative Cases
6. Run eval against staging. Publish baseline scores in ``evaluation/RESULTS.md``.
7. Add a "negative" check: for "no answer" questions, assert ``requires_clarification=true``.

### Day 5 — Integration Tests
8. ``tests/test_e2e.py`` (pytest): upload doc → poll until status=completed → query → assert source appears in response. Use ``MOCK_N8N=false`` (point to staging).
9. ``tests/test_tenant_isolation.py``: tenant A's user cannot retrieve tenant B's docs.

### Day 6 — Load Test (Stretch)
10. Locust: 20 concurrent users for 5 min on /chat/query. Record p95 latency in RESULTS.md.

## Learning Resources
- RAGAS: https://docs.ragas.io/en/stable/
- pytest fixtures: https://docs.pytest.org/en/stable/how-to/fixtures.html
- Locust: https://locust.io/
"@

"M11" = @"
## Skills Required
- **Must-have:** Technical writing, Markdown, screenshots, Excalidraw / Mermaid, presentation skills.
- **Nice-to-have:** ScreenToGif / OBS for demo recording, Figma, video editing basics.

## Detailed Step-by-Step Plan
### Day 1 — README Polish
1. Pull repo. Read ``ARCHITECTURE.md``, ``docs/DEPLOYMENT.md``, ``docs/DEMO.md`` end-to-end.
2. Rewrite ``README.md`` top section with: hero blurb, 1-screenshot, badges (build/coverage/license), 5-line quickstart.

### Day 2 — Sample Data
3. Define 3 demo tenant companies and pull their public PDFs:
   - **Tenant A** "MakeCo": 2-3 product manuals.
   - **Tenant B** "HelpDeskCo": IT SOPs.
   - **Tenant C** "MaintainCo": maintenance guides.
4. Store under ``evaluation/sample-data/<tenant>/``.

### Day 3 — Diagrams
5. Refine 3 Excalidraw files in ``docs/diagrams/``: open at https://excalidraw.com → File → Open → save back to ``.excalidraw``. Export PNG to ``docs/diagrams/png/`` for slides.
6. Verify Mermaid diagrams in ARCHITECTURE.md still render on GitHub.

### Day 4 — ADRs (Architecture Decision Records)
7. Create ``docs/adr/`` with one MD file per decision:
   - 001-why-voyage-embeddings.md
   - 002-deepseek-vs-openai.md
   - 003-no-redis.md
   - 004-ephemeral-uploads-pattern-A.md
   - 005-mcp-server.md

### Day 5 — Demo Script + Slides
8. Build 10-slide deck (Google Slides / PPT): problem → solution → architecture → demo screenshots → cost → roadmap.
9. Walk through ``docs/DEMO.md`` 3 times; refine timing.

### Day 6 — Record
10. Record 3-min demo video (OBS, 1080p): Web UI chat → WhatsApp upload → Claude Desktop MCP → eval scores. Upload to YouTube unlisted, link in README.

## Learning Resources
- ADR format: https://github.com/joelparkerhenderson/architecture-decision-record
- Excalidraw: https://excalidraw.com
- Mermaid live editor: https://mermaid.live
"@

"M12" = @"
## Skills Required
- **Must-have:** Twilio WhatsApp API, TwiML, async Python, httpx, file MIME validation, conversation memory patterns.
- **Nice-to-have:** Twilio status callbacks, media upload to S3, voice notes (stretch).
- **Note:** Tushar owns M4 + M12 — same code area, treat as one workstream.

## Detailed Step-by-Step Plan
### Day 1 — Sandbox + Pre-seed Map
1. (See M4 step 1-4 for Twilio sandbox setup.)
2. Pre-seed ``whatsapp_tenant_map`` table: INSERT 3 rows mapping your phone + 2 teammates' phones to the demo tenant.
3. Implement ``backend/app/bots/tenant_map.py`` with ``get_tenant_id_by_phone(from_number) -> Optional[UUID]``.

### Day 2 — Text Flow
4. Build ``backend/app/bots/whatsapp.py``: ``async def handle_message(from_number, body, conversation_id_or_new)``.
5. Look up tenant; if missing, reply ``"This number isn't registered. Please ask your admin to onboard you."``.
6. Call ``services/n8n_client.retrieve()`` and format response → TwiML.

### Day 3 — Media (Ephemeral Upload)
7. Detect ``MediaUrl0`` + ``MediaContentType0``. Download via httpx with Twilio basic auth.
8. ``services/file_validator.validate_upload`` (10 MB WhatsApp cap, MIME allowlist).
9. POST to N8N_EPHEMERAL_INGEST_WEBHOOK_URL with conversation_id.
10. Reply: ``"Indexed ✓ — ask me anything about this file for the next 60 minutes."``

### Day 4 — Conversation Memory
11. On every message, INSERT row into ``chat_messages`` with ``channel='whatsapp'``, ``conversation_id`` keyed by ``(tenant_id, from_number)``.
12. Pass last 5 messages as ``conversation_history`` to retrieve call.

### Day 5 — Twilio Signature Validation (HARD GATE)
13. Wire ``twilio.request_validator.RequestValidator`` against ``settings.TWILIO_AUTH_TOKEN``. Reject 403 if invalid (skip only if ``settings.DEBUG``).
14. Test: replay attack should be blocked.

### Day 6 — Demo Polish
15. Add typing-style UX: reply with quick ``"🤔 Thinking..."`` then send the answer in a second message (via Twilio REST API, not TwiML).
16. Pre-stage 3 sample queries + 1 sample PDF for the demo recording.

## Learning Resources
- Twilio Python helper: https://www.twilio.com/docs/libraries/python
- TwiML for WhatsApp: https://www.twilio.com/docs/whatsapp/api
- Media downloads: https://www.twilio.com/docs/usage/webhooks/messaging-webhooks#media
"@

"M13" = @"
## Skills Required
- **Must-have:** FastAPI, Next.js multi-step forms, validation (Pydantic + zod), file upload, tenant isolation patterns.
- **Nice-to-have:** Stripe (stretch — paid plans), email service (Resend/Postmark) for welcome mail.

## Detailed Step-by-Step Plan
### Day 1 — Design
1. Branch ``feat/onboarding``. Wireframe 3-step wizard:
   - Step 1: Company info (name, slug, industry).
   - Step 2: Admin user (name, email, password).
   - Step 3: Upload first document → "You're ready! Open chat →".
2. Draft DB extensions if any (most schema already present in ``tenants`` + ``users``).

### Day 2 — Backend
3. ``backend/app/api/onboarding.py``:
   - ``POST /onboarding/signup`` — accepts ``{company_name, slug, admin_email, admin_password, industry}``; creates tenant + super_admin user; returns JWT.
   - ``GET /onboarding/check-slug?slug=foo`` — returns ``{available: bool}``.
4. Enforce slug uniqueness + reserved-word blocklist (``admin``, ``api``, ``www``).

### Day 3 — Frontend Wizard
5. ``app/onboarding/page.tsx``: stepper component, useState for wizard data, validation per step (zod).
6. Step 1: company form + live slug availability check (debounced 500 ms).
7. Step 2: password strength meter; show terms checkbox.
8. Step 3: drag-drop one file → POST /admin/documents/upload (uses fresh JWT) → "Setting up…" loading state.

### Day 4 — Post-onboarding Redirect
9. After step 3: redirect to ``/chat`` with conversation pre-created and a system "Welcome — try asking…" message.

### Day 5 — Multi-tenant Isolation Test
10. Coordinate with M10: write ``tests/test_onboarding_isolation.py`` — onboard tenant A, onboard tenant B, confirm B cannot see A's document.

### Day 6 — Landing Page
11. ``app/page.tsx``: marketing landing — hero, 3 features, "Get started" CTA → /onboarding. Static HTML, no logic.

## Learning Resources
- Multi-step forms in React: https://www.smashingmagazine.com/2021/04/multi-step-form-react/
- Zod validation: https://zod.dev/
- Slug generation: https://github.com/Trott/slug
"@

}

# ─────────────────────────────────────────────────────────────────────────
# Apply
# ─────────────────────────────────────────────────────────────────────────
foreach ($mod in $blocks.Keys | Sort-Object) {
    $path = Join-Path $specsDir "MODULE_SPEC_$mod.md"
    if (-not (Test-Path $path)) {
        Write-Warning "Skipping missing $path"
        continue
    }
    $content = Get-Content -Raw $path
    if ($content -match [regex]::Escape($marker)) {
        Write-Host "[skip]   $mod already has skills section"
        continue
    }
    $append = "`r`n`r`n---`r`n$marker`r`n$($blocks[$mod])`r`n"
    Add-Content -Path $path -Value $append -NoNewline
    Write-Host "[ok]     $mod appended ($([math]::Round($append.Length/1024,1)) KB)"
}

Write-Host "`nDone. Review with: git diff --stat specs/"
