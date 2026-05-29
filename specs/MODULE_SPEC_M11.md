# MODULE_SPEC_M11 — Documentation & Demo

**Owner**: Member 11 | **Track**: Docs | **Branch**: `feat/docs`

## Role
README, architecture diagrams, setup guides, demo dataset (3 tenant companies), demo script, presentation slides.

## Day-by-Day Deliverables
| Day | Deliverable | Done? |
|---|---|---|
| 1 | Start README with architecture diagram. Define 3 demo companies. | ☐ |
| 2 | API documentation supplement (beyond Swagger auto-gen) | ☐ |
| 3 | n8n setup guide: import workflows + configure credentials | ☐ |
| 3 | Docker deployment guide: step-by-step from zero to running | ☐ |
| 4 | Demo dataset: 3 tenants with different document sets | ☐ |
| 5 | Seed script for demo: auto-create tenants + upload docs | ☐ |
| 5 | Record demo video OR prepare live demo script | ☐ |
| 6 | Architecture decision records (ADRs). Presentation slides. Final review. | ☐ |

## Files Owned
- `docs/`
- `evaluation/sample-data/`
- `README.md` (with M1)

## Demo Companies
| Company | Industry | Document Types | Slug |
|---|---|---|---|
| Bosch Support | Consumer appliances | Dishwasher manuals, error codes | `bosch-support` |
| TechDesk IT | Corporate IT helpdesk | SOPs, troubleshooting runbooks | `techdesk-it` |
| IndEquip Co | Industrial equipment | Maintenance guides, safety manuals | `indequip-co` |

## Demo Script (Day 6 rehearsal)
```
1. Open http://localhost:3000/onboarding
2. Register "Bosch Support" tenant (live, 30 seconds)
3. Upload 2 PDFs: dishwasher_manual.pdf + error_codes.pdf
4. Wait for status: completed (< 2 minutes)
5. Open Chat portal → ask: "How do I fix error E15?"
6. Show: grounded answer + citations panel + follow-up chips
7. Open WhatsApp on phone → send same question to Twilio sandbox
8. Show: WhatsApp reply received with answer
9. Demo tenant isolation: log in as Bosch → search for IT helpdesk content → "I don't have enough information"
```

## n8n Setup Guide Template
```markdown
# n8n Workflow Setup

1. Open http://localhost:5678
2. Log in (admin / n8nadmin)
3. Go to Workflows → Import from file
4. Import: n8n-workflows/ingestion-pipeline.json
5. Import: n8n-workflows/retrieval-pipeline.json
6. Configure credentials:
   - OpenAI API: Settings → Credentials → New → OpenAI
   - Postgres: Settings → Credentials → New → PostgreSQL
     host: postgres, port: 5432, db: ragplatform
7. Activate both workflows (toggle to Active)
8. Test: send POST to http://localhost:5678/webhook/retrieve
```

## Acceptance Criteria
- [ ] README has working Quick Start (tested on clean machine)
- [ ] n8n setup guide lets someone import workflows in < 10 minutes
- [ ] Docker guide: `docker compose up` works following the guide
- [ ] 3 demo companies with sample documents in `evaluation/sample-data/`
- [ ] Demo script rehearsed — runs in < 10 minutes
- [ ] Presentation slides exported as PDF in `docs/`
