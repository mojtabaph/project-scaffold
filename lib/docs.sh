#!/bin/bash
# lib/docs.sh - Documentation and memory system

generate_docs() {
  info "Documentation (doc/)"

  cat > "$PROJECT_PATH/doc/README.md" << 'EOF'
# Documentation

Master index for all project documentation.

## Quick Start
- QUICK_START.md - Get started in 5 minutes
- QUICK_REFERENCE.md - All commands

## Setup & Environment
- SETUP_GUIDE.md - Local development setup
- ENVIRONMENT.md - Environment variables and dependencies

## Technical
- ARCHITECTURE.md - System design and tech stack
- API.md - API specification
- DATABASE.md - Database schema

## Deployment & DevOps
- API_URL_CORS.md - CORS and API configuration
- CI_CD_SETUP.md - GitHub Actions setup
- GITHUB_ACTIONS.md - Complete CI/CD guide

## Project Management
- PHASES.md - Project phases and timeline
- STEPS.md - Development steps checklist
- PROJECT_STATE.md - Current project status
EOF

  cat > "$PROJECT_PATH/doc/QUICK_START.md" << 'EOF'
# Quick Start

## Setup
```bash
cp .env.example .env
docker compose up -d --build
```

## Access
- Frontend: http://localhost:3000
- Backend: http://localhost:8080
- Health: curl http://localhost:8080/api/health

## Stop
```bash
docker compose down
```
EOF

  cat > "$PROJECT_PATH/doc/QUICK_REFERENCE.md" << EOF
# Quick Reference

## Commands
- \`docker compose up -d --build\` - Start all services
- \`docker compose down\` - Stop services
- \`docker compose logs -f\` - View logs
- \`docker compose ps\` - Check status

## Memory System
- \`bash scripts/memory-read.sh\` - Load AI memory (first action of every session)
- \`bash scripts/memory-update.sh "summary" "tasks" "bugs" "code"\` - Save AI memory

## Git
- \`git add .\` - Stage changes
- \`git commit -m "feat: ..."\` - Commit
- \`git push origin main\` - Push

## Ports
- Frontend: 3000
- Backend: 8080
- Database: $DB (port: $DB_PORT)
EOF
  if [ "$USE_REDIS" = "yes" ]; then
    cat >> "$PROJECT_PATH/doc/QUICK_REFERENCE.md" << 'EOF'
- Redis: 6379
EOF
  fi

  log "doc/"
}

generate_memory_system() {
  info "AI Memory System"

  mkdir -p "$PROJECT_PATH/state"

  cat > "$PROJECT_PATH/state/README.md" << 'EOF'
# AI Memory System

This directory contains the AI memory database.

## Files
- `project_state.db` - SQLite database for AI memory
- `memory_backup.json` - Backup of memory data

## Usage
Every AI session starts with loading memory:
\`\`\`bash
bash scripts/memory-read.sh
\`\`\`

To update memory:
\`\`\`bash
bash scripts/memory-update.sh "summary" "tasks" "bugs" "code"
\`\`\`
EOF
  log "state/"

  # Memory read script
  cat > "$PROJECT_PATH/scripts/memory-read.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

DB_FILE="state/project_state.db"

if [ ! -f "$DB_FILE" ]; then
  echo "No memory database found. Creating new one..."
  sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE IF NOT EXISTS memory (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  key TEXT UNIQUE NOT NULL,
  value TEXT NOT NULL,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT OR REPLACE INTO memory (key, value) VALUES
  ('summary', 'Project just started. No tasks completed yet.'),
  ('tasks', '[]'),
  ('bugs', '[]'),
  ('code', '{}');
SQL
fi

echo "=== AI Memory State ==="
echo ""
sqlite3 "$DB_FILE" "SELECT key || ': ' || value FROM memory;" 2>/dev/null || echo "Memory is empty."
echo ""
echo "======================="
EOF
  chmod +x "$PROJECT_PATH/scripts/memory-read.sh"
  log "scripts/memory-read.sh"

  # Memory update script
  cat > "$PROJECT_PATH/scripts/memory-update.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

DB_FILE="state/project_state.db"

if [ $# -lt 4 ]; then
  echo "Usage: $0 <summary> <tasks> <bugs> <code>"
  echo "Example: $0 'Fixed login bug' '["login"]' '["none"]' '{"auth.js": "v2"}'"
  exit 1
fi

SUMMARY="$1"
TASKS="$2"
BUGS="$3"
CODE="$4"

if [ ! -f "$DB_FILE" ]; then
  echo "Creating memory database..."
  sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE IF NOT EXISTS memory (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  key TEXT UNIQUE NOT NULL,
  value TEXT NOT NULL,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL
fi

sqlite3 "$DB_FILE" << SQL
INSERT OR REPLACE INTO memory (key, value, updated_at) VALUES
  ('summary', '$SUMMARY', datetime('now')),
  ('tasks', '$TASKS', datetime('now')),
  ('bugs', '$BUGS', datetime('now')),
  ('code', '$CODE', datetime('now'));
SQL

echo "Memory updated successfully!"
echo ""
echo "=== Updated State ==="
sqlite3 "$DB_FILE" "SELECT key || ': ' || value FROM memory;"
echo "====================="
EOF
  chmod +x "$PROJECT_PATH/scripts/memory-update.sh"
  log "scripts/memory-update.sh"

  cat > "$PROJECT_PATH/AGENTS.md" << 'EOF'
# AI Agent Instructions

## Session Start
Every session MUST start with:
\`\`\`bash
bash scripts/memory-read.sh
\`\`\`

## Memory Update
After completing tasks, update memory:
\`\`\`bash
bash scripts/memory-update.sh "summary" "tasks" "bugs" "code"
\`\`\`

## Rules
1. Always read memory first
2. Update memory after changes
3. Follow project conventions
4. Run tests before commits
EOF
  log "AGENTS.md"
}
