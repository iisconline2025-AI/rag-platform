# Generates .github/instructions/M*.instructions.md per-module Copilot scopes.
$ErrorActionPreference = "Stop"
$root    = Split-Path -Parent $PSScriptRoot
$instDir = Join-Path $root ".github\instructions"
New-Item -ItemType Directory -Path $instDir -Force | Out-Null

$modules = @(
  [pscustomobject]@{ id="M1";  name="Integration / Tech Lead";   owner="OPEN";                glob="{specs/openapi.yaml,docker-compose.yml,README.md,CHANGELOG.md,.github/**}"; desc="Repo gatekeeper, API contract owner, PR reviews, E2E smoke tests"; mustHave="Git/GitHub, OpenAPI 3.0, Markdown, Docker basics"; niceHave="GitHub Actions CI, Mermaid, semantic-release"; soft="Daily standup facilitation, PR triage, scope guardrails" },
  [pscustomobject]@{ id="M2";  name="Auth & Core";               owner="Keshav Kumar";        glob="{backend/app/main.py,backend/app/core/**,backend/app/api/auth.py,backend/alembic/**,backend/scripts/seed_admin.py,tests/test_auth.py}"; desc="FastAPI app, JWT auth, SQLAlchemy models, Alembic migrations"; mustHave="Python 3.11, FastAPI, Pydantic v2, SQLAlchemy 2.0, Alembic, python-jose JWT, bcrypt, pytest"; niceHave="Async SQLAlchemy, OAuth2 flow, slowapi"; soft="Security mindset, defensive input validation" },
  [pscustomobject]@{ id="M3";  name="Document & Chat APIs";      owner="Karthic V";           glob="{backend/app/api/admin.py,backend/app/api/chat.py,backend/app/services/n8n_client.py,backend/app/services/file_validator.py,tests/test_chat.py}"; desc="Upload, document mgmt, /chat/query proxy to n8n (mock-first)"; mustHave="FastAPI UploadFile, async Python, httpx, Pydantic v2, multipart, env config"; niceHave="Streaming responses, background tasks, n8n webhook conventions"; soft="Mock-first dev so FE isn't blocked" },
  [pscustomobject]@{ id="M4";  name="Webhooks (WhatsApp + Slack)"; owner="Tushar Srivastava"; glob="{backend/app/api/webhooks.py,backend/app/bots/slack.py,tests/test_webhooks.py}"; desc="WhatsApp/Slack/n8n callback receivers + signature validation"; mustHave="FastAPI, Twilio TwiML, HMAC sig validation, Slack Events API, ngrok"; niceHave="Slack Bolt SDK, async background tasks, retry/backoff"; soft="Webhook debugging discipline (always log raw payloads)" },
  [pscustomobject]@{ id="M5";  name="n8n Ingestion Pipeline";    owner="Kumari Priyanka";     glob="{n8n-workflows/ingestion-pipeline.json,n8n-workflows/ingest-ephemeral.json,docs/n8n-setup.md}"; desc="PDF/DOCX/URL extract -> chunk -> Voyage embed -> pgvector"; mustHave="n8n, JSON workflow editing, HTTP Request node, Function (JS) node, Postgres node, Voyage embeddings API"; niceHave="OpenAI gpt-4o vision OCR, pdf-parse, token chunking, n8n credentials mgmt"; soft="Workflow versioning hygiene (export JSON after every change)" },
  [pscustomobject]@{ id="M6";  name="n8n Retrieval (Agentic)";   owner="Shreya Shrivastava";  glob="{n8n-workflows/retrieval-pipeline.json,docs/n8n-setup.md}"; desc="AI Agent + Voyage rerank + Gemini self-check + DeepSeek fallback"; mustHave="n8n LangChain Agent node, tool-calling agents, pgvector kNN SQL, Voyage rerank, DeepSeek API, Gemini API"; niceHave="Prompt engineering for grounded answers, fallback chains"; soft="Faithfulness-first thinking; cite sources or say -I dont know-" },
  [pscustomobject]@{ id="M7";  name="Infrastructure & DB";       owner="OPEN (P0 BLOCKER)";   glob="{docker-compose.yml,backend/Dockerfile,frontend/Dockerfile,database/**,backend/scripts/cleanup_ephemeral.py,railway.json,vercel.json}"; desc="Neon Postgres + pgvector, Railway (backend+n8n), Vercel (FE), cron"; mustHave="Docker, docker-compose, PostgreSQL, pgvector, Neon, Railway, Vercel, env/secret mgmt, cron"; niceHave="Bash, GitHub Actions, Sentry, Grafana"; soft="P0 mindset: your Day-1 output unblocks M2/M5/M6" },
  [pscustomobject]@{ id="M8";  name="Frontend: Admin Portal";    owner="Ritika Gupta";        glob="{frontend/src/app/admin/**,frontend/src/components/admin/**,frontend/src/lib/api.ts,frontend/src/types/**}"; desc="Next.js admin dashboard: docs, users, tenants, settings"; mustHave="Next.js 14 App Router, TypeScript, TailwindCSS, React hooks, JWT mgmt, drag-drop"; niceHave="SWR/TanStack Query, shadcn/ui, openapi-typescript codegen, optimistic UI"; soft="Empty-state and error-state design discipline" },
  [pscustomobject]@{ id="M9";  name="Frontend: Chat Portal";     owner="Joy Das";             glob="{frontend/src/app/chat/**,frontend/src/components/chat/**}"; desc="ChatGPT-style UI: bubbles, citations, faithfulness badge, follow-ups"; mustHave="Next.js 14, TypeScript, TailwindCSS, React state, react-markdown"; niceHave="rehype-highlight, zustand, mobile-first design"; soft="Demo-quality polish (animations, autoscroll, typing dots)" },
  [pscustomobject]@{ id="M10"; name="Evaluation & Testing";      owner="Yashas H M";          glob="{evaluation/**,tests/**}"; desc="RAGAS eval harness, 30 Q&A test set, integration + isolation tests"; mustHave="Python, pytest, RAGAS, Pandas, prompt curation"; niceHave="Locust/k6 load test, GitHub Actions CI eval, Jupyter"; soft="Skeptical mindset: test the negative cases (-no answer- queries)" },
  [pscustomobject]@{ id="M11"; name="Documentation & Demo";      owner="OPEN";                glob="{docs/**,README.md,evaluation/sample-data/**,docs/diagrams/**}"; desc="README, ADRs, demo script, sample data, slide deck, demo video"; mustHave="Technical writing, Markdown, Excalidraw, screenshots, presentation skills"; niceHave="OBS/ScreenToGif, Figma, video editing"; soft="Audience empathy (write for someone who has never seen the project)" },
  [pscustomobject]@{ id="M12"; name="WhatsApp Bot Specialist";   owner="Tushar Srivastava";   glob="{backend/app/bots/whatsapp.py,backend/app/bots/tenant_map.py}"; desc="WhatsApp end-to-end: text Q&A + ephemeral PDF upload (10MB, 1h TTL)"; mustHave="Twilio WhatsApp API, TwiML, async httpx, MIME validation, conversation memory"; niceHave="Twilio status callbacks, S3 media, voice notes (stretch)"; soft="UX patience: WhatsApp users expect <5 s replies" },
  [pscustomobject]@{ id="M13"; name="Customer Onboarding";       owner="OPEN";                glob="{backend/app/api/onboarding.py,frontend/src/app/onboarding/**}"; desc="3-step tenant signup wizard + landing page"; mustHave="FastAPI, Next.js multi-step forms, validation (Pydantic + zod), file upload"; niceHave="Stripe (stretch), Resend/Postmark email"; soft="First-impression matters: wizard must be foolproof" }
)

foreach ($m in $modules) {
  $path = Join-Path $instDir ("$($m.id).instructions.md")
  $lines = @()
  $lines += '---'
  $lines += "applyTo: `"$($m.glob)`""
  $lines += "description: `"$($m.id) $($m.name) - $($m.desc)`""
  $lines += '---'
  $lines += ''
  $lines += "# $($m.id) - $($m.name)"
  $lines += ''
  $lines += "**Owner:** $($m.owner)  "
  $lines += "**Full spec:** [specs/MODULE_SPEC_$($m.id).md](../../specs/MODULE_SPEC_$($m.id).md)  "
  $lines += "**Files in scope:** ``$($m.glob)``"
  $lines += ''
  $lines += '## What this module does'
  $lines += $m.desc
  $lines += ''
  $lines += '## Required skills'
  $lines += "- **Must-have:** $($m.mustHave)"
  $lines += "- **Nice-to-have:** $($m.niceHave)"
  $lines += "- **Soft skills:** $($m.soft)"
  $lines += ''
  $lines += '## Mandatory rules when editing files in this scope'
  $lines += "1. Read the [full spec](../../specs/MODULE_SPEC_$($m.id).md) before changing code - it has the day-by-day plan, acceptance criteria, and learning resources."
  $lines += '2. Honour the repo-wide [locked stack](../copilot-instructions.md) - no new deps without M1 approval.'
  $lines += '3. Honour the API contract in [specs/openapi.yaml](../../specs/openapi.yaml). Contract changes need an M1-reviewed PR first.'
  $lines += '4. Multi-tenant isolation: every query touching tenant data MUST filter by `tenant_id`.'
  $lines += '5. No secrets in code. Read config from `app.core.config.settings` (Python) or `process.env.NEXT_PUBLIC_*` (frontend).'
  $lines += '6. Add at least one test (unit or integration) per PR.'
  $lines += '7. No `print()` in Python - use `logging`.'
  $lines += ''
  $lines += '## When generating code for this module'
  $lines += '- Prefer editing existing files over creating new ones.'
  $lines += '- Match existing style (Black/isort for Python, Prettier for TS).'
  $lines += "- Cite the spec section you're implementing in the PR description."
  $lines += '- If the spec is ambiguous, ask in the PR rather than guessing.'
  $lines += ''
  $lines += '## Cross-module dependencies'
  $lines += '- Upstream contract: `specs/openapi.yaml` (M1).'
  $lines += '- Shared models: `backend/app/models/models.py` (M2).'
  $lines += '- Shared n8n client: `backend/app/services/n8n_client.py` (M3).'

  $content = ($lines -join "`r`n") + "`r`n"
  Set-Content -Path $path -Value $content -NoNewline -Encoding UTF8
  Write-Host "[ok] wrote $($m.id).instructions.md"
}

Write-Host "`nDone. $($modules.Count) per-module files written to .github/instructions/"
