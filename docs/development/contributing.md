# Contributing

## Branching Strategy

```
main  ← protected · deploy-ready · only M1 merges here
  └── dev  ← integration branch · all PRs target here
       ├── feat/auth           (M2)
       ├── feat/admin-api      (M3)
       ├── feat/chat-api       (M3)
       ├── feat/webhooks       (M4)
       ├── feat/n8n-ingest     (M5)
       ├── feat/n8n-retrieve   (M6)
       ├── feat/infra          (M7)
       ├── feature/admin-UI    (M8)
       ├── feat/chat-ui        (M9)
       ├── feat/evaluation     (M10)
       └── feat/onboarding     (M13)
```

## PR Workflow

1. **Branch from `dev`**:
   ```bash
   git checkout dev
   git pull
   git checkout -b feat/<your-feature>
   ```

2. **Commit with conventional format**:
   ```
   feat(M2): add rate limiting to login endpoint
   fix(M3): handle empty query string in chat
   docs(M11): add deployment guide
   chore(M7): update docker-compose volumes
   ```

3. **Push and open PR targeting `dev`** (not `main`):
   ```bash
   git push -u origin feat/<your-feature>
   ```

4. **Wait for CI** — lint, pytest, Docker build must all pass

5. **Get code review** from at least one team member

6. **Squash merge** into `dev`

:::{warning}
Direct pushes to `main` and `dev` are **blocked** by branch protection. All changes must go through PRs with green CI.
:::

## Definition of Done

- [ ] Code matches the OpenAPI spec in `specs/openapi.yaml`
- [ ] Unit/integration tests pass
- [ ] No new lint warnings
- [ ] Docstrings on all public functions
- [ ] PR description explains what and why

## Commit Message Format

```
<type>(<scope>): <short description>

[optional body]

[optional footer]
```

**Types**: `feat`, `fix`, `docs`, `chore`, `test`, `refactor`, `ci`

**Scope**: Module number (e.g., `M2`, `M3`) or component name

## Code Style

- **Python**: Follow PEP 8, use type hints, docstrings on all public functions
- **TypeScript**: ESLint + Prettier, strict mode
- **SQL**: Uppercase keywords, lowercase identifiers
- **Markdown**: One sentence per line in docs

## Running Tests

```bash
# Backend tests (requires running Postgres)
cd backend
DATABASE_URL=postgresql+asyncpg://raguser:changeme@localhost:5432/ragplatform \
    pytest ../tests/ -v

# Or via Docker
docker compose run --rm backend pytest tests/ -v

# Evaluation dataset tests
pytest tests/test_evaluation_dataset.py -v
```
