# Generic Stack Protocol

Used when the declared stack has no dedicated file in `references/stacks/`. The dedicated files are examples, not limits — any language, framework, or project type is in scope. Follow this protocol instead of guessing or borrowing another ecosystem's habits.

---

## Principles

1. **The ecosystem's conventions win.** Use the official scaffolding tool when one exists (`cargo new`, `flutter create`, `dotnet new`, `mix new`, `npm create vite`, `rails new`, `swift package init`) rather than hand-rolling a layout. If the tool is not installed, replicate the layout it would produce.
2. **Standard tooling only.** The ecosystem's canonical build tool, package manager, formatter, and linter — no bespoke build scripts when a standard one exists.
3. **The de-facto test framework.** Every ecosystem has one (XCTest, flutter_test, RSpec, PHPUnit, ExUnit, GoogleTest, Terratest). Declare which you chose in the plan.
4. **Config via environment or the ecosystem's config idiom** (`.env.example`, `appsettings.json`, `config/*.exs`, `values.yaml`) — placeholders committed, real values gitignored. Never hardcode secrets.
5. **Confirm the tree before writing** — same rule as every other stack.

---

## Layout by Project Type

Adapt whichever applies; the language's conventions override this table when they conflict.

| Project type | Shape |
|---|---|
| **API service** | entry point + routing layer + business logic + data access, separated; health endpoint; containerfile if the ecosystem deploys that way |
| **Web UI** | framework scaffold + components/pages/routing split + typed API client layer |
| **CLI tool** | thin entry point that parses args (ecosystem's standard arg parser) and delegates to library code — logic must be testable without spawning the binary; `--help` and `--version`; meaningful exit codes |
| **Library / SDK** | public API surface in one clearly-bounded module; internals private; semver-ready package metadata; usage example in README; no I/O or global state at import time |
| **Mobile app** | platform scaffold (Xcode project, Gradle module, `flutter create`); screens/navigation/state/services split; API layer isolated for testing |
| **Desktop app** | platform/framework scaffold (Electron, Tauri, .NET MAUI, Qt); UI / app-logic split mirroring the mobile pattern |
| **Data pipeline** | stages as pure functions or tasks (extract/transform/load or DAG nodes); schema definitions for inputs and outputs; idempotent runs; sample fixture data for local runs |
| **ML project** | data prep / training / evaluation / inference as separate entry points; config-file-driven hyperparameters; pinned dependencies; model artifacts gitignored |
| **Infrastructure-as-code** | modules with typed variables and outputs; per-environment configuration separated from module logic; `validate`/`plan` runnable locally; no credentials in code |
| **Embedded** | vendor toolchain project layout; hardware-abstraction layer separated from application logic so logic compiles and tests on the host |

---

## When Genuinely Unsure

If the ecosystem's conventions are ambiguous (two competing standards, unusual hybrid project), present both options in the confirmation step with a one-line trade-off each and let the user pick. Never silently invent a third layout.
