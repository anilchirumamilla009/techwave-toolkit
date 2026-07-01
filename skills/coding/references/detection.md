# Stack Detection Reference

## Primary Detection: Marker Files

Check for these files in the project root to determine the tech stack:

| Marker File | Stack | Reference |
|---|---|---|
| `go.mod` | Go | `stacks/go.md` |
| `Cargo.toml` | Rust | `stacks/rust.md` |
| `pom.xml` | Java (Maven) | `stacks/java.md` |
| `build.gradle` or `build.gradle.kts` | Java/Kotlin (Gradle) | `stacks/java.md` |
| `pyproject.toml` | Python (modern) | `stacks/python.md` |
| `requirements.txt` | Python (classic) | `stacks/python.md` |
| `package.json` + `tsconfig.json` | Node.js + TypeScript | `stacks/nodejs.md` |
| `package.json` (no tsconfig.json) | Node.js + JavaScript | `stacks/nodejs.md` (JS variant) |

## Secondary Detection: Framework Signals

If multiple marker files exist or the primary file is ambiguous, check for framework signals:

| Signal File/Pattern | Framework | Notes |
|---|---|---|
| `src/App.tsx` or `src/App.jsx` | React | Likely frontend-only |
| `next.config.js` or `next.config.ts` | Next.js | Full-stack React |
| `vite.config.ts` | Vite (likely React/Vue) | Check for `.tsx` files |
| `angular.json` | Angular | Frontend |
| `svelte.config.js` | SvelteKit | Frontend |
| `manage.py` | Django | Python web |
| `asgi.py` or `wsgi.py` | Django/FastAPI/Flask | Python web |
| `SpringApplication.run` in Java | Spring Boot | Java web |
| `@QuarkusMain` in Java | Quarkus | Java web |
| `gin.Default()` in Go | Gin | Go web |
| `echo.New()` in Go | Echo | Go web |

## Monorepo Edge Cases

When multiple marker files exist (monorepo):

1. Check for a root-level `package.json` with `workspaces` — this is a JavaScript monorepo
2. Check for a `go.work` file — this is a Go workspace (multi-module)
3. Check for multiple `pom.xml` files in subdirectories — Java multi-module Maven project
4. Check for a `Cargo.toml` with `[workspace]` — Rust workspace

**When monorepo is detected, ask the user:**
```
I detected a monorepo with multiple packages:
- packages/api (Node.js)
- packages/web (React)
- packages/worker (Python)

Which package would you like to scaffold? Or should I create a new package?
```

## Detection Bash Command

```bash
# Run this command to detect the stack
ls -1 go.mod Cargo.toml pom.xml build.gradle build.gradle.kts \
      pyproject.toml requirements.txt package.json tsconfig.json \
      next.config.js next.config.ts vite.config.ts angular.json 2>/dev/null
```

## Confidence Levels

| Confidence | Situation | Action |
|---|---|---|
| **High** | Single unambiguous marker file (go.mod, Cargo.toml, pom.xml) | Proceed without asking |
| **Medium** | `package.json` present (could be Node.js or React) | Check for React/Next/Vite signals before deciding |
| **Low** | Multiple marker files (monorepo) | List packages and ask user which to target |
| **None** | No marker files found | Ask user explicitly: "Which tech stack should I scaffold?" |

## Stack Aliases for User Input

When the user provides `$ARGUMENTS`, apply this alias table before looking up the reference:

```
nodejs, node, express, fastify, hapi, koa, nestjs, typescript, ts    → stacks/nodejs.md
python, fastapi, flask, django, uvicorn, aiohttp, tornado             → stacks/python.md
java, spring, springboot, spring-boot, quarkus, micronaut, maven      → stacks/java.md
kotlin, gradle                                                         → stacks/java.md
go, golang, gin, echo, fiber, chi, gorilla                            → stacks/go.md
react, nextjs, next, vite, cra, create-react-app, frontend            → stacks/react.md
rust, axum, actix, actix-web, warp, rocket, tokio                     → stacks/rust.md
```

If the user provides an alias not in this table, ask: "I don't recognize '[alias]'. Which tech stack did you mean?"
