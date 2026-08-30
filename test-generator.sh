#!/bin/bash
# test-generator.sh - test all selection combinations (without docker build)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATOR="$SCRIPT_DIR/setup-project.sh"
TEST_DIR="$SCRIPT_DIR/test-auto"
PASS=0; FAIL=0; TOTAL=0; CASES=0; CASE_FAIL=0

GREEN="\033[0;32m"; RED="\033[0;31m"; YELLOW="\033[1;33m"; CYAN="\033[0;36m"; RESET="\033[0m"
pass() { PASS=$((PASS+1)); TOTAL=$((TOTAL+1)); echo -e "  ${GREEN}[PASS]${RESET} $1"; }
fail() { FAIL=$((FAIL+1)); TOTAL=$((TOTAL+1)); echo -e "  ${RED}[FAIL]${RESET} $1"; }
info() { echo -e "${YELLOW}[INFO]${RESET} $1"; }
case_info() { echo -e "\n${CYAN}=== CASE $1: $2 ===${RESET}"; }
cleanup() { rm -rf "$TEST_DIR" 2>/dev/null || true; }

check_project() {
  local label="$1" eb="$2" ed="$3" er="$4" en="$5"
  local before=$FAIL
  for f in docker-compose.yml README.md STACK.md AGENTS.md brief/README.md .env.example .gitignore scripts/test.sh; do
    if [ -f "$TEST_DIR/$f" ]; then pass "[$label] File: $f"; else fail "[$label] File: $f (missing)"; fi
  done
  grep -q "## Selections" "$TEST_DIR/STACK.md" 2>/dev/null && pass "[$label] STACK.md: Selections" || fail "[$label] STACK.md: Selections missing"
  if [ "$eb" = "go" ]; then
    grep -q "go 1.23" "$TEST_DIR/backend/go.mod" 2>/dev/null && pass "[$label] go.mod 1.23" || fail "[$label] go.mod 1.23 missing"
  fi
  if [ -n "$ed" ] && [ "$ed" != "none" ]; then
    grep -q "$ed" "$TEST_DIR/docker-compose.yml" 2>/dev/null && pass "[$label] DB $ed" || fail "[$label] DB $ed missing"
  fi
  if [ "$er" = "yes" ]; then
    grep -q "redis:7-alpine" "$TEST_DIR/docker-compose.yml" 2>/dev/null && pass "[$label] redis" || fail "[$label] redis missing"
  else
    ! grep -q "redis:7-alpine" "$TEST_DIR/docker-compose.yml" 2>/dev/null && pass "[$label] no redis" || fail "[$label] redis should be absent"
  fi
  if [ "$en" = "yes" ]; then
    grep -q "nginx:stable-alpine" "$TEST_DIR/docker-compose.yml" 2>/dev/null && pass "[$label] nginx" || fail "[$label] nginx missing"
  else
    ! grep -q "nginx:stable-alpine" "$TEST_DIR/docker-compose.yml" 2>/dev/null && pass "[$label] no nginx" || fail "[$label] nginx should be absent"
  fi
  if command -v docker >/dev/null 2>&1; then
    (cd "$TEST_DIR" && docker compose config >/dev/null 2>&1) && pass "[$label] compose config" || fail "[$label] compose config invalid"
  fi
  if [ "$eb" = "go" ] && command -v go >/dev/null 2>&1; then
    (cd "$TEST_DIR/backend" && go vet ./... >/dev/null 2>&1) && pass "[$label] go vet" || fail "[$label] go vet failed"
  fi

  # Code quality checks
  if [ "$eb" = "go" ] && [ -f "$TEST_DIR/backend/.golangci.yml" ]; then
    pass "[$label] linting: .golangci.yml"
  elif [ "$eb" = "nodejs" ] && [ -f "$TEST_DIR/backend/.eslintrc.js" ]; then
    pass "[$label] linting: .eslintrc.js"
  elif [ "$eb" = "rust" ] && [ -f "$TEST_DIR/backend/clippy.toml" ]; then
    pass "[$label] linting: clippy.toml"
  fi

  # Frontend linting
  if [ -f "$TEST_DIR/frontend/.eslintrc.js" ] || [ -f "$TEST_DIR/frontend/.eslintrc.json" ]; then
    pass "[$label] linting: frontend eslint"
  fi
  if [ -f "$TEST_DIR/frontend/.prettierrc" ]; then
    pass "[$label] linting: frontend prettier"
  fi

  # Git hooks
  if [ -f "$TEST_DIR/.husky/pre-commit" ]; then
    pass "[$label] hooks: pre-commit"
  fi
  if [ -f "$TEST_DIR/.husky/commit-msg" ]; then
    pass "[$label] hooks: commit-msg"
  fi
  if [ -f "$TEST_DIR/.husky/pre-push" ]; then
    pass "[$label] hooks: pre-push"
  fi

  # CI/CD
  if [ -f "$TEST_DIR/.github/workflows/ci.yml" ]; then
    pass "[$label] cicd: ci.yml"
  fi
  if [ -f "$TEST_DIR/.github/workflows/deploy.yml" ]; then
    pass "[$label] cicd: deploy.yml"
  fi

  # Security
  if [ -f "$TEST_DIR/nginx/security-headers.conf" ]; then
    pass "[$label] security: headers"
  fi
  if [ -f "$TEST_DIR/nginx/rate-limit.conf" ]; then
    pass "[$label] security: rate-limit"
  fi
  if [ -f "$TEST_DIR/backend/cors.js" ]; then
    pass "[$label] security: cors"
  fi
  if [ -f "$TEST_DIR/backend/validation.js" ]; then
    pass "[$label] security: validation"
  fi

  # Observability
  if [ -f "$TEST_DIR/monitoring/prometheus.yml" ]; then
    pass "[$label] observability: prometheus"
  fi
  if [ -f "$TEST_DIR/monitoring/alert_rules.yml" ]; then
    pass "[$label] observability: alerts"
  fi
  if [ -f "$TEST_DIR/backend/logger.js" ]; then
    pass "[$label] observability: logger"
  fi
  if [ -f "$TEST_DIR/backend/health.js" ]; then
    pass "[$label] observability: health"
  fi

  # Multi-environment
  if [ -f "$TEST_DIR/.env.development" ]; then
    pass "[$label] environments: development"
  fi
  if [ -f "$TEST_DIR/.env.staging" ]; then
    pass "[$label] environments: staging"
  fi
  if [ -f "$TEST_DIR/.env.production" ]; then
    pass "[$label] environments: production"
  fi
  if [ -f "$TEST_DIR/backend/feature-flags.js" ]; then
    pass "[$label] environments: feature-flags"
  fi

  # Root tooling
  if [ -f "$TEST_DIR/Makefile" ]; then
    pass "[$label] root: Makefile"
  fi
  if [ -f "$TEST_DIR/scripts/memory-read.sh" ]; then
    pass "[$label] memory: read script"
  fi
  if [ -f "$TEST_DIR/scripts/memory-update.sh" ]; then
    pass "[$label] memory: update script"
  fi
  if [ -d "$TEST_DIR/.git" ]; then
    pass "[$label] git: initialized"
  fi
  if [ -f "$TEST_DIR/.github/ISSUE_TEMPLATE/bug_report.md" ]; then
    pass "[$label] github: bug template"
  fi
  if [ -f "$TEST_DIR/.github/ISSUE_TEMPLATE/feature_request.md" ]; then
    pass "[$label] github: feature template"
  fi
  if [ -f "$TEST_DIR/.github/PULL_REQUEST_TEMPLATE.md" ]; then
    pass "[$label] github: PR template"
  fi

  # Unit test skeletons
  if [ "$eb" = "go" ] && [ -f "$TEST_DIR/backend/main_test.go" ]; then
    pass "[$label] tests: go backend"
  fi
  if [ "$eb" = "nodejs" ] && [ -f "$TEST_DIR/backend/__tests__/health.test.js" ]; then
    pass "[$label] tests: nodejs backend"
  fi
  if [ "$eb" = "nodejs" ] && [ -f "$TEST_DIR/backend/jest.config.js" ]; then
    pass "[$label] tests: nodejs jest config"
  fi
  if [ "$eb" = "rust" ] && grep -q "#\[cfg(test)\]" "$TEST_DIR/backend/src/main.rs" 2>/dev/null; then
    pass "[$label] tests: rust backend"
  fi

  # Frontend test skeletons
  if [ -f "$TEST_DIR/frontend/__tests__/index.test.js" ] || [ -f "$TEST_DIR/frontend/src/__tests__/App.test.jsx" ] || [ -f "$TEST_DIR/frontend/src/__tests__/App.test.js" ] || [ -f "$TEST_DIR/frontend/src/app/app.component.spec.ts" ]; then
    pass "[$label] tests: frontend skeleton"
  fi
  if [ -f "$TEST_DIR/frontend/jest.config.mjs" ] || [ -f "$TEST_DIR/frontend/jest.config.js" ] || [ -f "$TEST_DIR/frontend/vitest.config.js" ] || [ -f "$TEST_DIR/frontend/karma.conf.js" ]; then
    pass "[$label] tests: frontend config"
  fi

  # Database migrations
  if [ -d "$TEST_DIR/backend/migrations" ]; then
    pass "[$label] migrations: directory"
  fi
  if [ -d "$TEST_DIR/backend/seeds" ]; then
    pass "[$label] migrations: seeds"
  fi
  if [ -f "$TEST_DIR/scripts/backup.sh" ]; then
    pass "[$label] migrations: backup"
  fi
  if [ -f "$TEST_DIR/scripts/restore.sh" ]; then
    pass "[$label] migrations: restore"
  fi

  # Multi-deployment
  if [ -d "$TEST_DIR/deploy/k8s" ]; then
    pass "[$label] deployment: kubernetes"
  fi
  if [ -d "$TEST_DIR/deploy/aws" ]; then
    pass "[$label] deployment: aws"
  fi
  if [ -d "$TEST_DIR/deploy/gcp" ]; then
    pass "[$label] deployment: gcp"
  fi
  if [ -d "$TEST_DIR/deploy/azure" ]; then
    pass "[$label] deployment: azure"
  fi

  # Code generation
  if [ -f "$TEST_DIR/scripts/generate.sh" ]; then
    pass "[$label] codegen: cli"
  fi

  # Advanced testing
  if [ -d "$TEST_DIR/tests/load" ]; then
    pass "[$label] testing: load"
  fi
  if [ -d "$TEST_DIR/tests/security" ]; then
    pass "[$label] testing: security"
  fi
  if [ -d "$TEST_DIR/tests/contract" ]; then
    pass "[$label] testing: contract"
  fi

  # Performance
  if [ -f "$TEST_DIR/nginx/compression.conf" ]; then
    pass "[$label] performance: compression"
  fi
  if [ -f "$TEST_DIR/backend/cache.js" ]; then
    pass "[$label] performance: cache"
  fi
  if [ -f "$TEST_DIR/backend/pool.js" ]; then
    pass "[$label] performance: connection-pool"
  fi

  # Developer Experience
  if [ -d "$TEST_DIR/.vscode" ]; then
    pass "[$label] dx: vscode"
  fi
  if [ -d "$TEST_DIR/.devcontainer" ]; then
    pass "[$label] dx: devcontainer"
  fi
  if [ -f "$TEST_DIR/scripts/cli.sh" ]; then
    pass "[$label] dx: cli"
  fi

  # Commit standards
  if [ -f "$TEST_DIR/commitlint.config.js" ]; then
    pass "[$label] commit: commitlint.config.js"
  fi
  if [ -f "$TEST_DIR/.editorconfig" ]; then
    pass "[$label] commit: .editorconfig"
  fi

  [ "$FAIL" -gt "$before" ] && CASE_FAIL=$((CASE_FAIL+1)) || true
}

run_case() {
  local label="$1" inputs="$2" eb="$3" ed="$4" er="$5" en="$6"
  CASES=$((CASES+1))
  case_info "$CASES" "$label"
  cleanup
  printf "$inputs" | bash "$GENERATOR" >/dev/null 2>&1 || true
  if [ ! -f "$TEST_DIR/docker-compose.yml" ]; then
    fail "[$label] project not generated"; CASE_FAIL=$((CASE_FAIL+1)); cleanup; return
  fi
  check_project "$label" "$eb" "$ed" "$er" "$en"
  cleanup
}

info "Testing all selection combinations (no docker build)..."
# inputs: Project, Backend, Frontend, CSS, DB, BackendTest, FrontendTest, Redis, Nginx, Confirm
# Backend variants
run_case "go"        'test-auto\n1\n1\n1\n1\n1\n1\n1\n1\nyes\n'        go postgres:16-alpine yes yes
run_case "nodejs"    'test-auto\n1\n2\n1\n1\n1\n1\n1\n1\nyes\n'        go postgres:16-alpine yes yes
run_case "rust"      'test-auto\n1\n3\n1\n1\n1\n1\n1\n1\nyes\n'        go postgres:16-alpine yes yes

# DB variants
run_case "db:mysql"  'test-auto\n1\n1\n1\n2\n1\n1\n1\n1\nyes\n'        go mysql:8.0 yes yes
run_case "db:mongo"  'test-auto\n1\n1\n1\n3\n1\n1\n1\n1\nyes\n'        go mongo:7 yes yes
run_case "db:sqlite" 'test-auto\n1\n1\n1\n4\n1\n1\n1\n1\nyes\n'        go none yes yes

# Redis/Nginx toggles
run_case "no-redis"  'test-auto\n1\n1\n1\n1\n1\n1\n2\n1\nyes\n'        go postgres:16-alpine no yes
run_case "no-nginx"  'test-auto\n1\n1\n1\n1\n1\n1\n1\n2\nyes\n'        go postgres:16-alpine yes no
run_case "minimal"   'test-auto\n1\n1\n1\n1\n1\n1\n2\n2\nyes\n'        go postgres:16-alpine no no

# Frontend variants
run_case "frontend:react" 'test-auto\n1\n1\n2\n1\n1\n1\n1\n1\nyes\n'  go postgres:16-alpine yes yes
run_case "frontend:vue"   'test-auto\n1\n1\n3\n1\n1\n1\n1\n1\nyes\n'  go postgres:16-alpine yes yes

echo ""
echo "========================================"
echo -e "  Cases: $CASES total, $CASE_FAIL failed"
echo -e "  Checks: ${GREEN}$PASS passed${RESET}, ${RED}$FAIL failed${RESET}, Total: $TOTAL"
echo "========================================"
[ "$FAIL" -eq 0 ] && echo -e "${GREEN}All tests passed!${RESET}" || echo -e "${RED}Some checks failed.${RESET}"
[ "$FAIL" -eq 0 ]
