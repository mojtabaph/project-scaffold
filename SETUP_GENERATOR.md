# Project Scaffold Generator — Usage Guide

Standard project structure generator: select stack → generate complete project (code + Docker + documentation + AI Memory System) → Git init → ready to deploy.

## Quick Start

### Windows (PowerShell)
```powershell
cd D:\projects
.\path\to\setup-project.ps1
```
(Launcher uses Git Bash — install: https://git-scm.com)

### Linux / macOS / Git Bash
```bash
cd ~/projects
chmod +x setup-project.sh
./setup-project.sh
```

## Interactive Prompts

```
1. Project name?              → Project name (letters, numbers, hyphens only)
2. Backend?                   → 1) Go  2) Node.js (Express)  3) Rust
3. Frontend?                  → 1) Next.js  2) React (Vite)  3) Vue (Vite)  4) Angular  5) Svelte (Vite)  6) Templ+htmx (Go SSR)
4. CSS Framework?             → 1) Tailwind  2) Bootstrap  3) Material UI  4) Chakra UI  5) Ant Design
5. Database?                  → 1) PostgreSQL  2) MySQL  3) MongoDB  4) SQLite (no service)
6. Testing (backend)?         → 1) Go Test  2) Jest  3) Mocha  4) None
7. Testing (frontend)?        → 1) Jest (Next.js) / Vitest (Vite) / Jasmine (Angular)  2) None
8. Redis?                     → 1) Yes  2) No
9. Nginx?                     → 1) Yes  2) No
10. Confirm?                  → yes / no
```

**Selections have real effects:** Skeleton code, Dockerfiles, database services, healthchecks, and test files are generated based on your choices (not just documentation).

## Generated Project Structure

```
my-project/
├── AGENTS.md              ← Agent rules (auto-loaded by opencode)
├── Makefile               ← Dev commands (make dev, make test, make migrate, ...)
├── docker-compose.yml     ← Backend + frontend + DB (with healthcheck/network/volume)
├── .env.example           ← Matches database selection
├── backend/               ← Working skeleton with /api/health + Dockerfile + tests
├── frontend/              ← Skeleton with selected CSS + multi-stage Dockerfile
├── scripts/
│   ├── memory-read.sh     ← Load AI memory (first action every session)
│   ├── memory-update.sh   ← Update AI memory
│   ├── test.sh            ← Run all tests
│   ├── migrate.sh         ← Database migrations
│   ├── backup.sh          ← Database backup
│   └── restore.sh         ← Database restore
├── state/project_state.db ← Machine memory (auto-populated on first run)
├── doc/                   ← 14 documentation files
├── brief/                 ← Custom TASKS.md / REQUIREMENTS.md for AI agent
├── nginx/                 ← nginx.conf + security headers (if selected)
├── monitoring/            ← Prometheus + Grafana config
├── deploy/                ← K8s / AWS / GCP / Azure templates
├── .github/
│   ├── workflows/         ← ci.yml + deploy.yml
│   └── ISSUE_TEMPLATE/    ← Bug report + Feature request
│   └── PULL_REQUEST_TEMPLATE.md
└── .husky/                ← Git hooks (pre-commit, commit-msg, pre-push)
```

## AI Memory System

- **First action every session:** `bash scripts/memory-read.sh`
- **End of each step:** `bash scripts/memory-update.sh "<summary>" "<tasks>" "<bugs>" "<code>"`
- Single fixed row (id=1) with auto-truncate — memory size is always bounded.
- On first run, state is populated with initial project status.

## Docker

```bash
cd my-project
cp .env.example .env
docker compose up -d --build
docker compose ps        # All services Up?
docker compose logs -f backend
```

- Database: Based on selection (postgres:16 / mysql:8 / mongo:7 / sqlite file) with healthcheck.
- Network and container names: `{project}-network`, `{project}-db`, `{project}-backend`, `{project}-frontend`.

## Deployment (GitHub Actions)

1. Push project to GitHub.
2. On server: `git clone` + `cp .env.example .env`.
3. In GitHub: Secrets → `SERVER_HOST`, `SERVER_USER`, `SERVER_SSH_KEY`.
4. Every push to `main` → SSH → `git pull` + `docker compose up -d --build`.

## CSS Framework Support

- **Next.js / React:** Full support (Tailwind config / CDN / npm: MUI, Chakra, AntD).
- **Vue / Svelte / Angular:** Tailwind full; Bootstrap and AntD via CDN; MUI/Chakra replaced with Bootstrap CDN (warning printed).

## Troubleshooting

| Problem | Solution |
|---------|----------|
| PowerShell won't execute | Use Git Bash or `powershell -ExecutionPolicy Bypass -File setup-project.ps1` |
| Port already in use | Change ports in docker-compose.yml |
| Memory not populated | `cd project && bash scripts/memory-update.sh "summary" "tasks" "bugs" "code"` |
| Docker error | `docker compose down -v` then `docker compose up -d --build` |

## Note

- The `setup-project.ps1` script is a launcher only — it delegates to `setup-project.sh` (single source of truth).

## Templ + htmx (Frontend Option 6)

- **SSR without separate frontend service:** HTML rendered directly by Go backend (`/` with templ + htmx from CDN)
- Backend forced to Go; CSS forced to Tailwind (CDN); Frontend Testing = None
- Files: `backend/view/index.templ` (source) + `index_templ.go` (generated with templ v0.3.1020) + `frontend_routes.go` (routes `/` and `/api/dbcheck` for htmx)
- After editing `.templ` run: `templ generate` (install: `go install github.com/a-h/templ/cmd/templ@latest`)
- Accompanying output: `/api/dbcheck` (database status for htmx) — "Check Database" button on page
