# TEAM_WORKFLOW.md — How We Work

## Branching Strategy
```
main          ← protected · deploy-ready · M1 merges only after E2E passes
  └── dev     ← integration · all PRs target here · M1 reviews
       ├── feat/auth           (M2)
       ├── feat/admin-api      (M3)
       ├── feat/chat-api       (M3)
       ├── feat/webhooks       (M4)
       ├── feat/n8n-ingest     (M5)
       ├── feat/n8n-retrieve   (M6)
       ├── feat/infra          (M7)
       ├── feat/admin-ui       (M8)
       ├── feat/chat-ui        (M9)
       ├── feat/evaluation     (M10)
       ├── feat/docs           (M11)
       ├── feat/whatsapp-bot   (M12)
       └── feat/onboarding     (M13)
```

## Day 1 Git Setup (all members)
```bash
git clone <repo-url>
cd rag-platform
git checkout dev
git checkout -b feat/<your-feature>   # see branch name above
cp .env.example .env                  # fill in your secrets
docker compose up -d                  # start postgres + n8n
```

## PR Rules
1. All PRs target `dev` — never `main`
2. PR title: `feat(module): description` or `fix(module): what it fixes`
3. PR must include:
   - What it does (2–3 sentences)
   - How to test it (curl command or test file)
   - Screenshot or test output
   - At least 1 passing test
4. M1 reviews within 2 hours on sprint days
5. At least 1 peer approval before M1 merges

## Definition of Done
- [ ] Code runs locally without error
- [ ] Matches `specs/openapi.yaml` contract (for API changes)
- [ ] At least 1 test (unit, integration, or screenshot)
- [ ] PR created with description
- [ ] Reviewed by M1 or peer
- [ ] Merged to `dev`

## Daily Standup (Async · WhatsApp/Slack group · 9 AM)
```
✅ Done: [what I completed yesterday]
🔨 Today: [what I'm building today]
🚧 Blocked: [tag @M1 immediately — don't wait for standup]
```

## Sync Calls (Video)
| Day | Purpose |
|---|---|
| Day 1 evening | Kickoff — everyone has repo + branch + env working |
| Day 3 evening | n8n readiness check — are ingest + retrieve pipelines green? |
| Day 5 | WhatsApp live — send a real message from phone |
| Day 6 | Full demo rehearsal — all channels working |

## Commit Message Format
```
type(scope): short description

Examples:
feat(auth): add JWT refresh token endpoint
fix(chat): handle empty n8n response gracefully
test(retrieval): add tenant isolation test
docs(readme): update local setup instructions
chore(deps): upgrade fastapi to 0.111
```

## Agent Usage Tracking (required)
Each member must maintain `agent_usage/M<N>_usage.md`:
```markdown
## Session: [date]
### Prompt
[what you asked Claude]
### Output
[summary of what it generated]
### Corrections
[what you had to fix manually]
### Token count
[from /cost or /stats]
```
Export your Claude Code session with `/export` after each session and save to `agent_usage/`.

## Conflict Resolution
- File ownership is defined in `CLAUDE.md` — if you need to edit another member's file, raise a PR and tag the owner
- Architecture disputes → M1 decides
- API contract disputes → M1 decides after team discussion

## Emergency Protocol
If you are blocked and it's blocking others:
1. Post immediately in group chat (don't wait for standup)
2. Tag @M1 and the relevant module owner
3. M1 will pair with you or reassign within 1 hour
