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


---
<!-- AUTO-APPENDED:SKILLS-V1 -->
## Skills Required
- **Must-have:** Git/GitHub (PRs, branching, merge conflicts), reading OpenAPI/YAML, writing Markdown docs, basic Docker, REST API contracts.
- **Nice-to-have:** GitHub Actions CI, Mermaid diagrams, Postman/Insomnia, semantic-release.
- **Soft skills:** Daily standup facilitation, unblocking teammates, scope guardrails.

## Detailed Step-by-Step Plan
### Day 1 — Repo & Contract Lock
1. Verify main builds clean: `docker compose config` and `cd backend && python -m compileall app`.
2. Tag the lock-in commit: `git tag v0.1-day1 && git push --tags`.
3. Create GitHub Project board with columns: Backlog / In-Progress / Review / Done.
4. Add issue templates: `.github/ISSUE_TEMPLATE/bug.md`, `feature.md`.
5. Open one tracking issue per module (M2…M13) and assign owner.
6. Post Slack message with: repo URL, branch policy, `MODULE_SPEC_M*.md` link per person, daily standup time (15-min, 10:00 IST).

### Day 2-3 — Active Gatekeeping
7. Review every PR within 2 hours (sprint-mode SLA). Run smoke test before approving.
8. Maintain `CHANGELOG.md` — one bullet per merged PR.
9. Watch for contract drift: if anyone edits `specs/openapi.yaml` outside of you, revert and discuss.

### Day 4-5 — Integration
10. Coordinate the `MOCK_N8N=false` cutover: announce 1-hour freeze, M3+M5+M6 in same call.
11. Run end-to-end smoke: upload PDF → verify chunks in DB → query via web UI → verify citation → query via WhatsApp.
12. File bugs found as P0/P1/P2 issues; reassign to module owner.

### Day 6 — Demo
13. Record 3-min demo video per `docs/DEMO.md`.
14. Push final `v1.0-demo` tag. Run `git log --oneline v0.1-day1..HEAD | wc -l` for retro stats.

## Learning Resources
- OpenAPI 3.0 spec: https://swagger.io/specification/
- Conventional commits: https://www.conventionalcommits.org/
- GitHub flow: https://docs.github.com/en/get-started/quickstart/github-flow
