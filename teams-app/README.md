# Teams App Package (M14)

Sideloadable Microsoft Teams app for the RAG bot. See `specs/MODULE_SPEC_M14.md`.

## Contents
- `manifest.json` — app manifest. `${{TEAMS_APP_ID}}` must be replaced with the
  Azure Bot **Microsoft App ID** before packaging.
- `color.png` — **192×192** color icon (add before packaging — not committed).
- `outline.png` — **32×32** transparent outline icon (add before packaging).

## Build & sideload
```bash
# 1. Replace ${{TEAMS_APP_ID}} with your real App ID (or use Teams Toolkit env substitution).
# 2. Add color.png (192x192) and outline.png (32x32) to this folder.
# 3. Zip the three files at the root of the archive:
cd teams-app && zip ../rag-bot-teams.zip manifest.json color.png outline.png

# 4. Teams client → Apps → Manage your apps → Upload a custom app → choose the zip.
```

## Azure setup (one-time)
1. Azure Portal → create an **Azure Bot** resource → record **Microsoft App ID** + create a client secret.
2. Bot → **Channels** → add **Microsoft Teams**.
3. Bot → **Configuration** → Messaging endpoint:
   `https://<your-host>/webhooks/teams/messages` (use a dev tunnel locally).
4. Put the App ID / secret in `.env` as `TEAMS_APP_ID` / `TEAMS_APP_PASSWORD`.
5. Pre-seed `teams_workspace_map (aad_tenant_id, tenant_id)` for the tenant.
6. Link users via `POST /webhooks/teams/onboard` (admin) before they chat.
