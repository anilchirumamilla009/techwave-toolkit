# Changelog

## 0.8.0 — 2026-07-15

### Added
- **`/qa` now generates a manual test plan** (`docs/TEST_PLAN-<feature>.md`): concrete numbered steps with real data values, observable expected results, P1–P3 priorities, acceptance-criteria traceability, boundary/negative/authorization case derivation, regression checklist, and sign-off table. New reference: `skills/qa/references/manual-test-plan.md`.

### Security / consent
- **Pinned graphify install** to `graphifyy==0.9.16` everywhere (skills, shared protocol, `scripts/setup-kg.sh`) — no more unpinned `pip install`.
- **Consent gate on Step 0**: skills now ask once before installing graphify, editing `.gitignore`, or running `graphify claude install`. Declining falls back to Stack Config + marker-file detection for the rest of the conversation.

### Hook fixes (`hooks/compliance-scan.sh`)
- Findings now exit **2** instead of 1 so the warning is fed back to the model (Claude Code `PostToolUse` semantics) — previously the model never saw its own violations.
- Fixed single-quote detection: `\x27` is not valid inside a POSIX ERE bracket expression, so credentials in single quotes (`password = 'secret'`) were silently missed.
- Guarded the `jq` stdin parse against non-JSON input, which previously killed the script under `set -e`.
- Replaced the phantom `CLAUDE_TOOL_FILE_PATH` env-var fallback with a real `sed` parse of the hook's stdin JSON.
- `file`-command availability is now checked before use.
- Copilot hook now invokes the script via `bash` explicitly (script is not committed with an executable bit).

### Fixes
- **Step 0.2 now refreshes an existing graph** (`graphify .`, incremental via AST cache) before reading it — skills no longer act on a stale `GRAPH_REPORT.md`; previously an existing `graphify-out/` was reused as-is. `scripts/setup-kg.sh` refreshes likewise.
- `skills/test-plan` shim frontmatter renamed `qa` → `test-plan` (duplicate skill name collided with `skills/qa`).
- Marketplace name aligned to `techwave` so the documented `tw-dev@techwave` install commands work; Copilot install command in README corrected.
- Stale `claude plugin details techwave-toolkit` reference in the orchestrator updated to `tw-dev`.
- `scripts/setup-kg.sh` existence check aligned with the skills (`GRAPH_REPORT.md`, was `graph.json`).
- Removed committed `scripts/__pycache__/` bytecode; `.gitignore` now excludes `__pycache__/` and fixes the `.idea/` entry.
- `/requirements` skips the knowledge-graph build entirely for greenfield projects with no source files.
- Added `homepage` to `plugin.json`.

## 0.7.0

- Renamed plugin `techwave-dev` → `tw-dev`; `test-plan` skill renamed to `qa` (shim kept for back-compat).
- Token-efficiency optimization pass across all skills.

## Earlier

- Copilot CLI compatibility (`hooks/copilot-hooks.json`, `user-invocable` frontmatter).
- Initial skills: orchestrator, requirements, design, coding (multi-agent), qa, compliance.
