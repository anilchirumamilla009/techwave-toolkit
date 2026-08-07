# Changelog

## 2026-08-05 — plugin split: tw-qa + tw-hooks extracted (tw-dev 0.10.0, tw-qa 0.1.0, tw-hooks 0.1.0)

### Added
- **New `tw-qa` plugin (0.1.0)** — the `/qa` skill moved out of tw-dev into `plugins/tw-qa/`, installable independently: `claude plugin install tw-qa@techwave`. Ships its own copy of the shared knowledge-graph protocol so it has no dependency on tw-dev.
- **`/qa` is manual-QA-planning only (skill 0.13.0)** — its sole job is drafting the manual testing plan for what the coding agent changed: `docs/test/TEST_PLAN-<feature>.md` (+ importable CSV) with full step-by-step instructions, a dedicated **Test Data Creation** section (numbered TD-* steps with concrete values, observable confirmations, and cleanup), boundary/negative/authorization case derivation, manual accessibility checks when a UI changed, regression checklist, and sign-off. It detects the change set from the coding summary or git evidence and scopes the plan to it.
- **All automated testing is `/coding`'s job (tw-dev)** — its test agents must cover **all unit and integration test cases** for the change (new key rule in the coding skill). `/qa` writes no test code of any kind — stub/E2E generation removed entirely along with the `test-creation-doc.md`, `frameworks.md`, and `test-types.md` references — and reports automated-coverage gaps back to `/coding`.
- **New `tw-hooks` plugin (0.1.0)** — with the toolkit split across plugins, the guardrail hooks moved out of tw-dev into a shared plugin every install should include (`claude plugin install tw-hooks@techwave`). Carries the existing `PostToolUse` compliance scan (hardcoded credentials, PII in logs, AWS keys — warnings rebranded `[tw-hooks]`) **plus a new `PreToolUse` sensitive-data guard** that blocks Read/Bash/PowerShell calls which would expose secret material: reading `.env` (templates like `.env.example` stay allowed), `*.pem`/`*.key`/`id_rsa*`, keystores, `credentials.json`/`service-account*.json`, `~/.aws/credentials`, `.netrc`, `*.tfstate`, `secrets.*`, `.npmrc`/`.pypirc`/`.docker/config.json` — and shell commands that `cat`/`base64`/`curl`/`scp`/`Get-Content` those files. Blocked calls feed guidance back to the model (use variable names via the template, never values). tw-dev no longer ships hooks.

### Changed (tw-dev 0.10.0) — requirements moved out: tw-ba output is the pipeline input
- **`skills/requirements` removed** (back-compat shim kept, non-invocable) — requirements drafting is a BA activity owned by tw-ba's `/ba`; the dev plugin no longer duplicates it.
- **The orchestrator now takes the BA package as its requirements input**: Step 1 checks `docs/ba/<feature>/` first and, when found, loads the FRD/RTM as the authoritative requirements (a ticket then contributes only metadata). The phase sequence starts at `/design`; with no BA package and no usable acceptance criteria it recommends running `/ba` first (proceeding from raw text only if the user insists), and it never drafts requirements itself. Bug tickets go straight to `/coding` with the ticket text as context.

### Changed (tw-dev 0.10.0) — client review feedback on generated code quality
- **Coding Standards section added to the coding skill, enforced by the Validator** (new `Standards` verdict line + Check 3.5): no source file over ~300 lines (hard fail at 400 — addresses the 3200-line-file complaint), decomposition planned in the confirmed tree; one **global constants module** per component (`src/constants.ts` / `app/constants.py` / project convention) — no scattered per-feature constant files, no inline or duplicated magic values. Standards travel verbatim into subagent delegation and are baked into the coding, backend-coding, and UI-coding agents' plans and rules.
- **Unit-test correctness checklist added to the test agents** (unit, backend, UI): one behavior per test, arrange–act–assert, assertions on observable behavior only, no tautological or assertion-free tests, mock only external boundaries, deterministic and order-independent, and per public function a happy + boundary + specific error path.
- **Fixed a Validator bug that permitted TODO-stub tests**: Check 3 read "No empty test bodies (only `// TODO: implement` stubs are acceptable)" — it now fails empty bodies, TODO stubs, assertion-free and tautological tests, mocked-unit-under-test, and non-deterministic tests.
- `skills/qa` removed from tw-dev; the orchestrator's Phase 4 now invokes `/qa` from tw-qa when installed, and proposes the sequence without QA (with an install hint) when it isn't.
- `skills/test-plan` back-compat shim now points to the tw-qa plugin instead of a relative path inside tw-dev.
- README, copilot-instructions, and marketplace descriptions updated accordingly.

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
