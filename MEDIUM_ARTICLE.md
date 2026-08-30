# I Built a Project Generator That Saves Hours of Setup Time — Here's How

Every time I start a new project, I waste 2-3 hours setting up the same boilerplate: Docker, CI/CD, linting, testing, folder structure, and documentation.

And if I'm working with AI agents, I need a memory system so they don't lose context between sessions.

I got tired of repeating myself.

So I built **project-scaffold** — a shell-based generator that creates production-ready projects in 60 seconds.

---

## What It Does

Run one command and follow 10 simple prompts:

```bash
bash setup-project.sh
```

The generator asks you:

- Project name
- Backend (Go / Node.js / Rust)
- Frontend (Next.js / React / Vue / Angular / Svelte / Templ)
- CSS Framework (Tailwind / Bootstrap / Material UI)
- Database (PostgreSQL / MySQL / MongoDB / SQLite)
- Testing (backend / frontend)
- Redis (yes/no)
- Nginx (yes/no)

**Selections have real effects.** The generator creates actual working code based on your choices — not just empty folders.

---

## What You Get

Here's what a generated project looks like:

```
my-project/
├── backend/              # Working /api/health + Dockerfile + tests
├── frontend/             # Skeleton with CSS + multi-stage Dockerfile
├── docker-compose.yml    # All services with healthchecks
├── Makefile              # make dev, make test, make migrate
├── scripts/              # Memory, test, migrate, backup scripts
├── state/                # SQLite memory for AI agents
├── AGENTS.md             # AI agent rules
├── nginx/                # Security headers (if selected)
├── monitoring/           # Prometheus + Grafana
├── deploy/               # K8s / AWS / GCP / Azure
├── .github/              # CI/CD + Issue/PR templates
└── .husky/               # Git hooks
```

---

## The 5 Features I'm Most Proud Of

**1. AI Memory System**

AI agents lose context when you start a new session. The memory system fixes this:

```bash
# Start every session
bash scripts/memory-read.sh

# Save progress after completing a task
bash scripts/memory-update.sh "Fixed login bug" "['auth']" "['none']" '{"auth.js": "v2"}'
```

Memory is stored in SQLite, so it's fast and reliable.

**2. Unit Test Skeletons**

The generator creates test files with describe/it blocks for every stack:

- **Go:** `main_test.go` with health endpoint tests
- **Node.js:** `__tests__/health.test.js` with jest + supertest
- **Rust:** `#[cfg(test)]` inline module
- **Frontend:** Vitest/Jest test files for each framework

You get **686 automated checks** across 11 test scenarios.

**3. Production-Ready Docker**

Every generated project includes:

- Multi-stage Dockerfiles (smaller images, faster builds)
- Healthchecks for all services
- Nginx with security headers and rate limiting
- Proper networking between services

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f backend
```

**4. Full CI/CD Pipeline**

GitHub Actions workflows are generated automatically:

- **ci.yml:** Lint → Test → Build (on every push)
- **deploy.yml:** SSH → Pull → Rebuild (on push to main)

Just add your server secrets and you're deployed.

**5. Developer Experience**

The generator includes tools that make daily development smoother:

- **Makefile:** One command for everything
- **Git hooks:** Auto-lint on commit
- **VS Code config:** Extensions and settings
- **DevContainer:** Ready for GitHub Codespaces

---

## Architecture: 18 Independent Modules

The generator is built with a modular architecture — each file handles one feature:

- `backend.sh` — Go/Node.js/Rust + test skeletons
- `frontend.sh` — Next.js/React/Vue/Angular/Svelte + Dockerfiles
- `docker.sh` — Compose + Makefile + Nginx
- `docs.sh` — Memory System + AGENTS.md
- `cicd.sh` — GitHub Actions + Issue/PR templates
- `security.sh` — CORS, rate-limit, headers
- `monitoring.sh` — Prometheus, Grafana
- `environments.sh` — dev/staging/production
- `migrations.sh` — migrate, backup, restore
- `deployment.sh` — K8s, AWS, GCP, Azure
- `linting.sh` — ESLint, Prettier, GolangCI
- `hooks.sh` — Git hooks + commitlint
- `testing.sh` — Advanced testing tools
- `performance.sh` — Compression, caching, CDN
- `dx.sh` — VS Code, DevContainer, CLI
- `codegen.sh` — Code generation
- `config.sh` — Configuration management
- `utils.sh` — Shared helpers

Each module is independent. You can add/remove features without breaking others.

---

## The Numbers

After building the generator, I ran the test suite:

```
Cases: 11 total, 0 failed
Checks: 686 passed, 0 failed
All tests passed!
```

**11 test scenarios** covering all backends, databases, frontends, and configurations.

**686 automated checks** verifying file existence, content correctness, Docker Compose validity, linting configs, git hooks, CI/CD workflows, security headers, monitoring configs, and test skeletons.

---

## Try It Out

```bash
# Clone the generator
git clone https://github.com/mojtabaph/project-scaffold.git
cd project-scaffold

# Run it
bash setup-project.sh

# Follow prompts, then:
cd your-project
docker compose up -d --build
```

That's it. You now have a working project with Docker, CI/CD, testing, and AI memory.

---

## What's Next

I'm planning to add:

- More backends: Python (FastAPI), Deno, Bun
- More frontends: Solid.js, Qwik, Astro
- Terraform templates for cloud deployment
- Docker Swarm support
- Kubernetes Helm charts

---

## Conclusion

If this saves you time, give it a ⭐ on GitHub:

**[github.com/mojtabaph/project-scaffold](https://github.com/mojtabaph/project-scaffold)**

Thanks for reading!
