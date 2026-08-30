# project-scaffold

Standard project structure generator with Docker, AI Memory System, and multi-stack support.

## Features

- **Backends:** Go 1.23 / Node.js 24 / Rust 1.82
- **Frontends:** Next.js 14 / React 18 / Vue 3 / Angular 17 / Svelte 4 / Templ + htmx
- **Databases:** PostgreSQL 18 / MySQL 8 / MongoDB 7 / SQLite
- **Infra:** Redis 7, Nginx stable-alpine, Docker Compose, GitHub Actions
- **AI Memory System:** `AGENTS.md` + `state/project_state.db` + `scripts/` + `brief/` for agent handoff

## Quick Start

```bash
# Windows (PowerShell) - launches Git Bash
./setup-project.ps1

# Linux / macOS / Git Bash
bash setup-project.sh
```

Follow the interactive prompts:

1. Project name (default: `test`)
2. Backend (Go / Node.js / Rust)
3. Frontend (Next.js / React / Vue / Angular / Svelte / Templ)
4. CSS Framework (Tailwind / Bootstrap / Material UI / Chakra / Ant Design)
5. Database (PostgreSQL / MySQL / MongoDB / SQLite)
6. Testing (backend / frontend)
7. Redis / Nginx (optional)
8. Confirm `yes`

## Generated Project Structure

```
my-project/
  backend/          # Go / Node / Rust
  frontend/         # Next / React / Vue / ...
  nginx/            # nginx.conf (if selected)
  doc/              # 14 docs
  brief/            # Put custom TASKS.md / REQUIREMENTS.md for AI agent
  scripts/          # memory-read.sh, memory-update.sh, test.sh
  state/            # project_state.db (SQLite)
  AGENTS.md         # Agent rules (auto-loaded by opencode)
  STACK.md          # Selected stack + versions
  docker-compose.yml
  .env.example
```

## AI Agent Handoff

```bash
cd my-project
# First action every session
bash scripts/memory-read.sh

# Verify project health
bash scripts/test.sh   # or npm test

# After each completed step
bash scripts/memory-update.sh "<summary>" "<tasks>" "<bugs>" "<code>"
```

See `doc/QUICK_REFERENCE.md` for all commands.

## Testing the Generator

```bash
bash test-generator.sh   # 11 cases, 686 checks (all stacks, all databases, all frontends)
```

## Requirements

- Git Bash (Windows) or bash (Linux/macOS)
- Docker 24+ / Docker Compose v2
- Go 1.23+ (if using Go backend, for `go vet` checks)

## License

MIT

## Blog Post

Read the full article on Medium: [I Built a Project Generator That Saves Hours of Setup Time — Here's How](https://medium.com/@mojtaba.ph6265/i-built-a-project-generator-that-saves-hours-of-setup-time-heres-how-7cfffba3f95b?sharedUserId=mojtaba.ph6265)
