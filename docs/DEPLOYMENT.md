# Deployment Guide — IISc Grounded Agentic RAG Platform

> Total cost: **~$10 one-time + ~$5/mo**. Set up time: **~45 min**.

---

## 0. Prerequisites

- GitHub repo: https://github.com/iisconline2025-AI/rag-platform
- Cards / accounts: Vercel, Railway, Neon, Voyage, DeepSeek, Google AI Studio (Gemini), Twilio, OpenAI

---

## 1. Neon — Postgres + pgvector (FREE)

1. Sign up at https://neon.tech
2. Create project → region **Singapore** (lowest latency from India).
3. In the SQL Editor, paste and run [`database/init.sql`](../database/init.sql). This creates extensions + schema.
4. Copy the **pooled connection string** → save as `DATABASE_URL` in your `.env`:
   ```
   postgresql+asyncpg://USER:PASSWORD@ep-xxxx-pooler.aws.neon.tech/ragplatform?ssl=require
   ```

---

## 2. Voyage AI — Embeddings + Rerank (FREE 200M tokens)

1. Sign up: https://www.voyageai.com/
2. Dashboard → API Keys → create → save as `VOYAGE_API_KEY`.
3. No deployment — used directly from n8n HTTP Request nodes.

---

## 3. DeepSeek — Generation (~$5 one-time)

1. Sign up: https://platform.deepseek.com
2. **BEFORE 31 MAY 2026** — buy $5 credit while the 75% off promo is live (gets you ~$20 of usage).
3. API Keys → create → save as `DEEPSEEK_API_KEY`.
4. Models: `deepseek-v4-flash` (default), `deepseek-v4-pro` (hard-query fallback).

---

## 4. Gemini — Self-check (FREE)

1. Sign up: https://aistudio.google.com
2. Create API key → save as `GEMINI_API_KEY`.
3. Model: `gemini-3.5-flash`.

---

## 5. OpenAI — Insurance + Vision OCR ($5 prepaid)

1. Sign up: https://platform.openai.com
2. Buy $5 credit, **set hard limit to $10** in usage settings.
3. API Keys → save as `OPENAI_API_KEY`.

---

## 6. Twilio Sandbox — WhatsApp (FREE)

1. Sign up: https://www.twilio.com
2. Console → Messaging → Try it out → Send a WhatsApp message → activate Sandbox.
3. Copy SID + Auth Token → save as `TWILIO_ACCOUNT_SID` / `TWILIO_AUTH_TOKEN`.
4. Webhook URL (set after deploying backend in step 8): `https://<your-railway-app>/webhooks/whatsapp`

---

## 7. Railway — Backend + n8n (~$5/mo)

1. Sign up: https://railway.app, link GitHub.
2. New Project → Deploy from GitHub repo → `iisconline2025-AI/rag-platform`.
3. Add two services:
   - **backend**: root dir `backend`, Dockerfile build. Set all env vars from `.env.example`.
   - **n8n**: deploy the official `n8nio/n8n` Docker image. Set `DB_TYPE=postgresdb` + Neon credentials so n8n persists workflows in Neon (free tier).
4. Add **cron job**: `python -m scripts.cleanup_ephemeral` every hour.
5. Note the public URLs. Update `N8N_*_WEBHOOK_URL` vars in backend service.

### Importing n8n workflows
1. Open `https://<n8n-railway-url>` and log in.
2. Workflows → Import from File → import the three JSON files in [`n8n-workflows/`](../n8n-workflows/):
   - `ingestion-pipeline.json`
   - `retrieval-pipeline.json`
   - `ingest-ephemeral.json`
3. Activate each workflow. Copy webhook URLs into Railway backend env vars.

---

## 8. Vercel — Frontend (FREE)

1. Sign up: https://vercel.com, link GitHub.
2. Import project → root dir `frontend`. Framework: Next.js.
3. Env vars: `NEXT_PUBLIC_API_URL=https://<your-railway-backend-url>`.
4. Deploy. URL: `https://rag-platform-<hash>.vercel.app`.

---

## 9. Smoke Test

```bash
# Health check
curl https://<railway-backend>/health

# MCP discovery
curl https://<railway-backend>/mcp/info

# Mock query (MOCK_N8N=true)
curl -X POST https://<railway-backend>/chat/query \
  -H "Content-Type: application/json" \
  -d '{"query":"test"}'
```

When all three return 200, **flip `MOCK_N8N=false`** in Railway and redeploy. Real RAG is live.

---

## 10. Domain (optional)

- Vercel: project → Domains → add `app.<your-domain>`.
- Railway: project → Settings → add `api.<your-domain>`.

---

## Cost Watchdog

Set up **billing alerts** on every provider on day 1:
- DeepSeek: alert at $5
- OpenAI: hard cap $10 (already set in step 5)
- Voyage: alert at 150M tokens
- Railway: alert at $10/mo

Run weekly: `python -m scripts.cost_report` (TODO M10).
