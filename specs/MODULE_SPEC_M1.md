# MODULE_SPEC_M1 — Tech Lead / Integration

**Owner**: Member 1 | **Track**: Lead | **Branch**: N/A (works on main docs + reviews all PRs)

## Role
API contract owner, integration glue, PR gatekeeper, final E2E testing, demo orchestration.

## Day-by-Day Deliverables
| Day | Deliverable | Done? |
|---|---|---|
| 1 | Create GitHub repo + branching strategy + push existing code + share spec with team | ☐ |
| 1 | Finalize `specs/openapi.yaml` — this is the contract for all 13 members | ☐ |
| 1 | Create `.env.example` with all required variables | ☐ |
| 2 | Review PRs from M2, M7 — resolve early interface issues | ☐ |
| 3 | Mid-sprint review: confirm n8n pipelines (M5, M6) are on track | ☐ |
| 4 | Integration day: wire all services, resolve mismatches | ☐ |
| 5 | Cross-system test: Web UI + WhatsApp + Slack all working | ☐ |
| 6 | Final E2E smoke test + merge `dev → main` + demo orchestration | ☐ |

## Files Owned
- `specs/openapi.yaml`
- `docker-compose.yml` (with M7)
- `README.md`, `CLAUDE.md`, `PROJECT_SPEC.md`, `ARCHITECTURE.md`, `SKILLS.md`, `TEAM_WORKFLOW.md`

## PR Review SLA
- Respond to all PRs within **2 hours** on sprint days
- Merge criteria: code works + 1 test + description + peer approval

## E2E Smoke Test (Day 6)
```bash
# 1. docker compose up -d
# 2. alembic upgrade head
# 3. python -m app.scripts.seed_admin
# 4. Upload test PDF → verify status = "completed"
# 5. POST /chat/query → verify grounded answer with citations
# 6. Send WhatsApp message → verify TwiML reply received
# 7. All health checks green: GET /health
```

## Acceptance Criteria
- [ ] All team members have repo access and working local environment
- [ ] All 13 PRs reviewed and merged to `dev` before Day 6
- [ ] E2E smoke test passes on clean `docker compose up`
- [ ] Demo runs without errors
