# Editable Diagram Sources

Three Excalidraw files for the team to refine.

| File                                              | Source for                         |
| ------------------------------------------------- | ---------------------------------- |
| [system-overview.excalidraw](system-overview.excalidraw)     | ARCHITECTURE.md §1 high-level diagram |
| [agentic-loop.excalidraw](agentic-loop.excalidraw)           | ARCHITECTURE.md §3 retrieval loop  |
| [two-upload-paths.excalidraw](two-upload-paths.excalidraw)   | ARCHITECTURE.md §2 upload paths    |

## How to edit

1. Install **Excalidraw** VS Code extension (already done by M1).
2. Open the `.excalidraw` file — it opens in the Excalidraw editor.
3. Draw or refine. Save (`Ctrl+S`).
4. **Export to PNG** (Excalidraw menu) into `artifacts/screenshots/` for demo slides.
5. **Keep the corresponding Mermaid diagram in `ARCHITECTURE.md` in sync.** GitHub renders Mermaid natively in the README — that's our authoritative version.

## Why both Mermaid + Excalidraw?

- **Mermaid in ARCHITECTURE.md** → renders automatically on GitHub. Zero install. Text-diffs in PRs.
- **Excalidraw** → pretty hand-drawn look for demo-day slides. PNG export.

Mermaid is the source of truth. Excalidraw is for polished visuals.
