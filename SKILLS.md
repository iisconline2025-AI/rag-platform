# SKILLS.md — Platform Capabilities Reference

> What this platform can and cannot do. Read before building any new feature.

## What the Platform Does (Skills)

### 1. Document Ingestion
- **Input**: PDF, DOCX, TXT file upload OR public URL
- **Process**: Extract text → chunk (512 tokens, 50 overlap) → embed → store in pgvector
- **Output**: Queryable knowledge base per tenant
- **Time**: < 2 minutes for a 50-page PDF

### 2. Grounded Q&A
- **Input**: Natural language question + tenant_id + conversation history
- **Process**: Embed query → cosine similarity search → assemble context → GPT generation
- **Output**: Answer with inline source citations (document title + page number)
- **Guarantee**: Only answers from uploaded documents. Says "I don't know" if no relevant chunk found.

### 3. Citation Extraction
- Every answer maps to specific chunks with: document title, page number, chunk text, similarity score
- Frontend displays collapsible citations panel

### 4. Follow-up Question Generation
- GPT generates 3 contextually relevant follow-up questions after each answer
- Displayed as clickable chips in the chat UI

### 5. Conversation Memory
- Each conversation stores full message history
- History included in retrieval context window (last 10 messages)
- Available on Web UI and WhatsApp channel

### 6. Multi-Tenant Isolation
- Tenant A's documents are NEVER retrieved for Tenant B's queries
- Enforced at DB level: all queries include `WHERE tenant_id = :tenant_id`
- Verified by M10's isolation test suite

### 7. Multi-Channel Delivery
- **Web Chat**: Full UI with citations, follow-ups, conversation history
- **WhatsApp**: Text answer + truncated citations via Twilio TwiML
- **Slack**: Answer posted as thread reply to `@mention`

### 8. Admin Document Management
- Upload, view status (pending/processing/completed/failed), delete
- View chunk count per document
- URL ingestion (scrape and index a web page)

### 9. Tenant Onboarding Wizard
- Self-service: company info → admin user → first document upload → ready to query
- New tenant can onboard without M13's help after wizard is built

### 10. User Management
- Admin can invite users, assign roles (admin / user)
- Super-admin can manage all tenants

## What the Platform Does NOT Do
- ❌ Execute code or make changes to external systems
- ❌ Answer questions outside the uploaded knowledge base (grounded only)
- ❌ Store or process private production data without tenant consent
- ❌ Generate answers without citing a source
- ❌ Access the internet at query time (only at ingestion time for URL sources)
- ❌ Support voice queries (v2 roadmap)
- ❌ Autonomously update documents

## RAGAS Evaluation Metrics (M10 owns)
| Metric | Meaning | Target |
|---|---|---|
| Faithfulness | Answer claims supported by retrieved context | ≥ 0.85 |
| Answer Relevancy | Answer addresses the question | ≥ 0.80 |
| Context Precision | Retrieved chunks are relevant | ≥ 0.75 |
| Context Recall | Expected source appears in top-K | ≥ 0.80 |
| Citation Coverage | Answers with ≥ 1 citation | ≥ 90% |
| Tenant Isolation | Cross-tenant query leakage | 0% |
