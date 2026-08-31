#!/bin/bash
# test-generator.sh - test all selection combinations (without docker build)
# Super heavy tests with negative validation
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

  # =========================================================================
  # CORE FILES
  # =========================================================================
  for f in docker-compose.yml README.md STACK.md AGENTS.md brief/README.md .env.example .gitignore scripts/test.sh; do
    if [ -f "$TEST_DIR/$f" ]; then pass "[$label] File: $f"; else fail "[$label] File: $f (missing)"; fi
  done
  grep -q "## Selections" "$TEST_DIR/STACK.md" 2>/dev/null && pass "[$label] STACK.md: Selections" || fail "[$label] STACK.md: Selections missing"

  # =========================================================================
  # BACKEND-SPECIFIC POSITIVE TESTS
  # =========================================================================
  if [ "$eb" = "go" ]; then
    grep -q "go 1.23" "$TEST_DIR/backend/go.mod" 2>/dev/null && pass "[$label] go.mod 1.23" || fail "[$label] go.mod 1.23 missing"
    [ -f "$TEST_DIR/backend/main.go" ] && pass "[$label] go: main.go" || fail "[$label] go: main.go missing"
    [ -f "$TEST_DIR/backend/main_test.go" ] && pass "[$label] go: main_test.go" || fail "[$label] go: main_test.go missing"
    [ -f "$TEST_DIR/backend/.golangci.yml" ] && pass "[$label] go: .golangci.yml" || fail "[$label] go: .golangci.yml missing"
  fi
  if [ "$eb" = "nodejs" ]; then
    [ -f "$TEST_DIR/backend/package.json" ] && pass "[$label] nodejs: package.json" || fail "[$label] nodejs: package.json missing"
    [ -f "$TEST_DIR/backend/index.js" ] && pass "[$label] nodejs: index.js" || fail "[$label] nodejs: index.js missing"
    [ -f "$TEST_DIR/backend/jest.config.js" ] && pass "[$label] nodejs: jest.config.js" || fail "[$label] nodejs: jest.config.js missing"
    [ -d "$TEST_DIR/backend/__tests__" ] && pass "[$label] nodejs: __tests__/" || fail "[$label] nodejs: __tests__/ missing"
  fi
  if [ "$eb" = "rust" ]; then
    [ -f "$TEST_DIR/backend/Cargo.toml" ] && pass "[$label] rust: Cargo.toml" || fail "[$label] rust: Cargo.toml missing"
    [ -f "$TEST_DIR/backend/src/main.rs" ] && pass "[$label] rust: src/main.rs" || fail "[$label] rust: src/main.rs missing"
    grep -q "#\[cfg(test)\]" "$TEST_DIR/backend/src/main.rs" 2>/dev/null && pass "[$label] rust: test module" || fail "[$label] rust: test module missing"
  fi

  # =========================================================================
  # BACKEND NEGATIVE TESTS - GO
  # =========================================================================
  if [ "$eb" = "go" ]; then
    ! [ -f "$TEST_DIR/backend/cache.js" ] && pass "[$label] neg-go: no cache.js" || fail "[$label] neg-go: cache.js should not exist"
    ! [ -f "$TEST_DIR/backend/logger.js" ] && pass "[$label] neg-go: no logger.js" || fail "[$label] neg-go: logger.js should not exist"
    ! [ -f "$TEST_DIR/backend/validation.js" ] && pass "[$label] neg-go: no validation.js" || fail "[$label] neg-go: validation.js should not exist"
    ! [ -f "$TEST_DIR/backend/health.js" ] && pass "[$label] neg-go: no health.js" || fail "[$label] neg-go: health.js should not exist"
    ! [ -f "$TEST_DIR/backend/pool.js" ] && pass "[$label] neg-go: no pool.js" || fail "[$label] neg-go: pool.js should not exist"
    ! [ -f "$TEST_DIR/backend/feature-flags.js" ] && pass "[$label] neg-go: no feature-flags.js" || fail "[$label] neg-go: feature-flags.js should not exist"
    ! [ -f "$TEST_DIR/backend/cors.js" ] && pass "[$label] neg-go: no cors.js" || fail "[$label] neg-go: cors.js should not exist"
    ! [ -f "$TEST_DIR/backend/package.json" ] && pass "[$label] neg-go: no package.json" || fail "[$label] neg-go: package.json should not exist"
    ! [ -f "$TEST_DIR/backend/__tests__/health.test.js" ] && pass "[$label] neg-go: no health.test.js" || fail "[$label] neg-go: health.test.js should not exist"
    ! [ -f "$TEST_DIR/backend/jest.config.js" ] && pass "[$label] neg-go: no jest.config.js" || fail "[$label] neg-go: jest.config.js should not exist"
  fi

  # =========================================================================
  # BACKEND NEGATIVE TESTS - NODE.JS
  # =========================================================================
  if [ "$eb" = "nodejs" ]; then
    ! [ -f "$TEST_DIR/backend/main.go" ] && pass "[$label] neg-nodejs: no main.go" || fail "[$label] neg-nodejs: main.go should not exist"
    ! [ -f "$TEST_DIR/backend/go.mod" ] && pass "[$label] neg-nodejs: no go.mod" || fail "[$label] neg-nodejs: go.mod should not exist"
    ! [ -f "$TEST_DIR/backend/main_test.go" ] && pass "[$label] neg-nodejs: no main_test.go" || fail "[$label] neg-nodejs: main_test.go should not exist"
    ! [ -f "$TEST_DIR/backend/.golangci.yml" ] && pass "[$label] neg-nodejs: no .golangci.yml" || fail "[$label] neg-nodejs: .golangci.yml should not exist"
    ! [ -f "$TEST_DIR/backend/src/main.rs" ] && pass "[$label] neg-nodejs: no src/main.rs" || fail "[$label] neg-nodejs: src/main.rs should not exist"
    ! [ -f "$TEST_DIR/backend/Cargo.toml" ] && pass "[$label] neg-nodejs: no Cargo.toml" || fail "[$label] neg-nodejs: Cargo.toml should not exist"
  fi

  # =========================================================================
  # BACKEND NEGATIVE TESTS - RUST
  # =========================================================================
  if [ "$eb" = "rust" ]; then
    ! [ -f "$TEST_DIR/backend/main.go" ] && pass "[$label] neg-rust: no main.go" || fail "[$label] neg-rust: main.go should not exist"
    ! [ -f "$TEST_DIR/backend/go.mod" ] && pass "[$label] neg-rust: no go.mod" || fail "[$label] neg-rust: go.mod should not exist"
    ! [ -f "$TEST_DIR/backend/package.json" ] && pass "[$label] neg-rust: no package.json" || fail "[$label] neg-rust: package.json should not exist"
    ! [ -f "$TEST_DIR/backend/cache.js" ] && pass "[$label] neg-rust: no cache.js" || fail "[$label] neg-rust: cache.js should not exist"
  fi

  # =========================================================================
  # NODE.JS POSITIVE TESTS (JS files should exist)
  # =========================================================================
  if [ "$eb" = "nodejs" ]; then
    [ -f "$TEST_DIR/backend/cache.js" ] && pass "[$label] nodejs-pos: cache.js" || fail "[$label] nodejs-pos: cache.js missing"
    [ -f "$TEST_DIR/backend/logger.js" ] && pass "[$label] nodejs-pos: logger.js" || fail "[$label] nodejs-pos: logger.js missing"
    [ -f "$TEST_DIR/backend/validation.js" ] && pass "[$label] nodejs-pos: validation.js" || fail "[$label] nodejs-pos: validation.js missing"
    [ -f "$TEST_DIR/backend/health.js" ] && pass "[$label] nodejs-pos: health.js" || fail "[$label] nodejs-pos: health.js missing"
    [ -f "$TEST_DIR/backend/pool.js" ] && pass "[$label] nodejs-pos: pool.js" || fail "[$label] nodejs-pos: pool.js missing"
    [ -f "$TEST_DIR/backend/feature-flags.js" ] && pass "[$label] nodejs-pos: feature-flags.js" || fail "[$label] nodejs-pos: feature-flags.js missing"
    [ -f "$TEST_DIR/backend/cors.js" ] && pass "[$label] nodejs-pos: cors.js" || fail "[$label] nodejs-pos: cors.js missing"
  fi

  # =========================================================================
  # DATABASE TESTS
  # =========================================================================
  if [ -n "$ed" ] && [ "$ed" != "none" ]; then
    grep -q "$ed" "$TEST_DIR/docker-compose.yml" 2>/dev/null && pass "[$label] DB: $ed present" || fail "[$label] DB: $ed missing"
  fi
  if [ "$ed" = "none" ]; then
    ! grep -q "postgres:16" "$TEST_DIR/docker-compose.yml" 2>/dev/null && pass "[$label] neg-db: no postgres" || fail "[$label] neg-db: postgres should be absent"
    ! grep -q "mysql:8" "$TEST_DIR/docker-compose.yml" 2>/dev/null && pass "[$label] neg-db: no mysql" || fail "[$label] neg-db: mysql should be absent"
    ! grep -q "mongo:7" "$TEST_DIR/docker-compose.yml" 2>/dev/null && pass "[$label] neg-db: no mongo" || fail "[$label] neg-db: mongo should be absent"
  fi

  # =========================================================================
  # REDIS TESTS
  # =========================================================================
  if [ "$er" = "yes" ]; then
    grep -q "redis:7-alpine" "$TEST_DIR/docker-compose.yml" 2>/dev/null && pass "[$label] redis: present" || fail "[$label] redis: missing"
  else
    ! grep -q "redis:7-alpine" "$TEST_DIR/docker-compose.yml" 2>/dev/null && pass "[$label] neg-redis: no redis" || fail "[$label] neg-redis: redis should be absent"
  fi

  # =========================================================================
  # NGINX TESTS
  # =========================================================================
  if [ "$en" = "yes" ]; then
    grep -q "nginx:stable-alpine" "$TEST_DIR/docker-compose.yml" 2>/dev/null && pass "[$label] nginx: present" || fail "[$label] nginx: missing"
    [ -d "$TEST_DIR/nginx" ] && pass "[$label] nginx: directory" || fail "[$label] nginx: directory missing"
  else
    ! grep -q "nginx:stable-alpine" "$TEST_DIR/docker-compose.yml" 2>/dev/null && pass "[$label] neg-nginx: no nginx service" || fail "[$label] neg-nginx: nginx should be absent"
    ! [ -d "$TEST_DIR/nginx" ] && pass "[$label] neg-nginx: no nginx dir" || fail "[$label] neg-nginx: nginx dir should be absent"
  fi

  # =========================================================================
  # DOCKER COMPOSE VALIDATION
  # =========================================================================
  if command -v docker >/dev/null 2>&1; then
    (cd "$TEST_DIR" && docker compose config >/dev/null 2>&1) && pass "[$label] compose: config valid" || fail "[$label] compose: config invalid"
  fi

  # =========================================================================
  # GO VET
  # =========================================================================
  if [ "$eb" = "go" ] && command -v go >/dev/null 2>&1; then
    (cd "$TEST_DIR/backend" && go vet ./... >/dev/null 2>&1) && pass "[$label] go: vet passed" || fail "[$label] go: vet failed"
  fi

  # =========================================================================
  # CODE QUALITY
  # =========================================================================
  if [ "$eb" = "go" ] && [ -f "$TEST_DIR/backend/.golangci.yml" ]; then
    pass "[$label] linting: .golangci.yml"
  elif [ "$eb" = "nodejs" ] && [ -f "$TEST_DIR/backend/.eslintrc.js" ]; then
    pass "[$label] linting: .eslintrc.js"
  elif [ "$eb" = "rust" ] && [ -f "$TEST_DIR/backend/clippy.toml" ]; then
    pass "[$label] linting: clippy.toml"
  fi
  if [ -f "$TEST_DIR/frontend/.eslintrc.js" ] || [ -f "$TEST_DIR/frontend/.eslintrc.json" ]; then
    pass "[$label] linting: frontend eslint"
  fi
  if [ -f "$TEST_DIR/frontend/.prettierrc" ]; then
    pass "[$label] linting: frontend prettier"
  fi

  # =========================================================================
  # GIT HOOKS
  # =========================================================================
  [ -f "$TEST_DIR/.husky/pre-commit" ] && pass "[$label] hooks: pre-commit" || fail "[$label] hooks: pre-commit missing"
  [ -f "$TEST_DIR/.husky/commit-msg" ] && pass "[$label] hooks: commit-msg" || fail "[$label] hooks: commit-msg missing"
  [ -f "$TEST_DIR/.husky/pre-push" ] && pass "[$label] hooks: pre-push" || fail "[$label] hooks: pre-push missing"

  # =========================================================================
  # CI/CD
  # =========================================================================
  [ -f "$TEST_DIR/.github/workflows/ci.yml" ] && pass "[$label] cicd: ci.yml" || fail "[$label] cicd: ci.yml missing"
  [ -f "$TEST_DIR/.github/workflows/deploy.yml" ] && pass "[$label] cicd: deploy.yml" || fail "[$label] cicd: deploy.yml missing"

  # =========================================================================
  # SECURITY
  # =========================================================================
  if [ "$en" = "yes" ]; then
    [ -f "$TEST_DIR/nginx/security-headers.conf" ] && pass "[$label] security: headers" || fail "[$label] security: headers missing"
    [ -f "$TEST_DIR/nginx/rate-limit.conf" ] && pass "[$label] security: rate-limit" || fail "[$label] security: rate-limit missing"
  fi

  # =========================================================================
  # OBSERVABILITY
  # =========================================================================
  [ -f "$TEST_DIR/monitoring/prometheus.yml" ] && pass "[$label] observability: prometheus" || fail "[$label] observability: prometheus missing"
  [ -f "$TEST_DIR/monitoring/alert_rules.yml" ] && pass "[$label] observability: alerts" || fail "[$label] observability: alerts missing"

  # =========================================================================
  # MULTI-ENVIRONMENT
  # =========================================================================
  [ -f "$TEST_DIR/.env.development" ] && pass "[$label] env: development" || fail "[$label] env: development missing"
  [ -f "$TEST_DIR/.env.staging" ] && pass "[$label] env: staging" || fail "[$label] env: staging missing"
  [ -f "$TEST_DIR/.env.production" ] && pass "[$label] env: production" || fail "[$label] env: production missing"

  # =========================================================================
  # ROOT TOOLING
  # =========================================================================
  [ -f "$TEST_DIR/Makefile" ] && pass "[$label] root: Makefile" || fail "[$label] root: Makefile missing"
  [ -f "$TEST_DIR/scripts/memory-read.sh" ] && pass "[$label] memory: read" || fail "[$label] memory: read missing"
  [ -f "$TEST_DIR/scripts/memory-update.sh" ] && pass "[$label] memory: update" || fail "[$label] memory: update missing"
  [ -d "$TEST_DIR/.git" ] && pass "[$label] git: initialized" || fail "[$label] git: not initialized"
  [ -f "$TEST_DIR/.github/ISSUE_TEMPLATE/bug_report.md" ] && pass "[$label] github: bug template" || fail "[$label] github: bug template missing"
  [ -f "$TEST_DIR/.github/ISSUE_TEMPLATE/feature_request.md" ] && pass "[$label] github: feature template" || fail "[$label] github: feature template missing"
  [ -f "$TEST_DIR/.github/PULL_REQUEST_TEMPLATE.md" ] && pass "[$label] github: PR template" || fail "[$label] github: PR template missing"

  # =========================================================================
  # TEST SKELETONS
  # =========================================================================
  if [ -f "$TEST_DIR/frontend/__tests__/index.test.js" ] || [ -f "$TEST_DIR/frontend/src/__tests__/App.test.jsx" ] || [ -f "$TEST_DIR/frontend/src/__tests__/App.test.js" ] || [ -f "$TEST_DIR/frontend/src/app/app.component.spec.ts" ]; then
    pass "[$label] tests: frontend skeleton"
  fi
  if [ -f "$TEST_DIR/frontend/jest.config.mjs" ] || [ -f "$TEST_DIR/frontend/jest.config.js" ] || [ -f "$TEST_DIR/frontend/vitest.config.js" ] || [ -f "$TEST_DIR/frontend/karma.conf.js" ]; then
    pass "[$label] tests: frontend config"
  fi

  # =========================================================================
  # DATABASE MIGRATIONS
  # =========================================================================
  [ -d "$TEST_DIR/backend/migrations" ] && pass "[$label] migrations: dir" || fail "[$label] migrations: dir missing"
  [ -d "$TEST_DIR/backend/seeds" ] && pass "[$label] migrations: seeds" || fail "[$label] migrations: seeds missing"
  [ -f "$TEST_DIR/scripts/backup.sh" ] && pass "[$label] migrations: backup" || fail "[$label] migrations: backup missing"
  [ -f "$TEST_DIR/scripts/restore.sh" ] && pass "[$label] migrations: restore" || fail "[$label] migrations: restore missing"

  # =========================================================================
  # DEPLOYMENT
  # =========================================================================
  [ -d "$TEST_DIR/deploy/k8s" ] && pass "[$label] deploy: k8s" || fail "[$label] deploy: k8s missing"
  [ -d "$TEST_DIR/deploy/aws" ] && pass "[$label] deploy: aws" || fail "[$label] deploy: aws missing"
  [ -d "$TEST_DIR/deploy/gcp" ] && pass "[$label] deploy: gcp" || fail "[$label] deploy: gcp missing"
  [ -d "$TEST_DIR/deploy/azure" ] && pass "[$label] deploy: azure" || fail "[$label] deploy: azure missing"
  [ -f "$TEST_DIR/scripts/deploy.sh" ] && pass "[$label] deploy: script" || fail "[$label] deploy: script missing"

  # =========================================================================
  # DEPLOY METHODS
  # =========================================================================
  if [ -f "$TEST_DIR/scripts/deploy.sh" ]; then
    grep -q "deploy_git" "$TEST_DIR/scripts/deploy.sh" 2>/dev/null && pass "[$label] deploy: method git" || fail "[$label] deploy: method git missing"
    grep -q "deploy_scp" "$TEST_DIR/scripts/deploy.sh" 2>/dev/null && pass "[$label] deploy: method scp" || fail "[$label] deploy: method scp missing"
    grep -q "deploy_rsync" "$TEST_DIR/scripts/deploy.sh" 2>/dev/null && pass "[$label] deploy: method rsync" || fail "[$label] deploy: method rsync missing"
    grep -q "deploy_docker" "$TEST_DIR/scripts/deploy.sh" 2>/dev/null && pass "[$label] deploy: method docker" || fail "[$label] deploy: method docker missing"
    grep -q "deploy_ci" "$TEST_DIR/scripts/deploy.sh" 2>/dev/null && pass "[$label] deploy: method ci" || fail "[$label] deploy: method ci missing"
    grep -q "deploy_local" "$TEST_DIR/scripts/deploy.sh" 2>/dev/null && pass "[$label] deploy: method local" || fail "[$label] deploy: method local missing"
    grep -q "select_method" "$TEST_DIR/scripts/deploy.sh" 2>/dev/null && pass "[$label] deploy: interactive menu" || fail "[$label] deploy: interactive menu missing"
  fi

  # =========================================================================
  # PRODUCTION DOCKER COMPOSE
  # =========================================================================
  [ -f "$TEST_DIR/docker-compose.prod.yml" ] && pass "[$label] prod: compose" || fail "[$label] prod: compose missing"
  if [ -f "$TEST_DIR/docker-compose.prod.yml" ]; then
    grep -q "restart: always" "$TEST_DIR/docker-compose.prod.yml" 2>/dev/null && pass "[$label] prod: restart policy" || fail "[$label] prod: restart policy missing"
    grep -q "APP_ENV=production" "$TEST_DIR/docker-compose.prod.yml" 2>/dev/null && pass "[$label] prod: APP_ENV" || fail "[$label] prod: APP_ENV missing"
    grep -q "\${DATABASE_URL}" "$TEST_DIR/docker-compose.prod.yml" 2>/dev/null && pass "[$label] prod: secrets env var" || fail "[$label] prod: secrets env var missing"
  fi

  # =========================================================================
  # PRODUCTION NGINX
  # =========================================================================
  if [ "$en" = "yes" ]; then
    [ -f "$TEST_DIR/nginx/nginx.prod.conf" ] && pass "[$label] prod: nginx" || fail "[$label] prod: nginx missing"
    if [ -f "$TEST_DIR/nginx/nginx.prod.conf" ]; then
      grep -q "ssl" "$TEST_DIR/nginx/nginx.prod.conf" 2>/dev/null && pass "[$label] prod: ssl" || fail "[$label] prod: ssl missing"
      grep -q "Strict-Transport-Security" "$TEST_DIR/nginx/nginx.prod.conf" 2>/dev/null && pass "[$label] prod: hsts" || fail "[$label] prod: hsts missing"
      grep -q "X-Frame-Options" "$TEST_DIR/nginx/nginx.prod.conf" 2>/dev/null && pass "[$label] prod: x-frame" || fail "[$label] prod: x-frame missing"
      grep -q "limit_req_zone" "$TEST_DIR/nginx/nginx.prod.conf" 2>/dev/null && pass "[$label] prod: rate-limit" || fail "[$label] prod: rate-limit missing"
      grep -q "gzip" "$TEST_DIR/nginx/nginx.prod.conf" 2>/dev/null && pass "[$label] prod: gzip" || fail "[$label] prod: gzip missing"
    fi
  fi

  # =========================================================================
  # BACKUP & RESTORE SCRIPTS
  # =========================================================================
  [ -f "$TEST_DIR/scripts/backup.sh" ] && pass "[$label] scripts: backup" || fail "[$label] scripts: backup missing"
  [ -f "$TEST_DIR/scripts/restore.sh" ] && pass "[$label] scripts: restore" || fail "[$label] scripts: restore missing"

  # =========================================================================
  # CODE GENERATION
  # =========================================================================
  [ -f "$TEST_DIR/scripts/generate.sh" ] && pass "[$label] codegen: cli" || fail "[$label] codegen: cli missing"

  # =========================================================================
  # ADVANCED TESTING
  # =========================================================================
  [ -d "$TEST_DIR/tests/load" ] && pass "[$label] testing: load" || fail "[$label] testing: load missing"
  [ -d "$TEST_DIR/tests/security" ] && pass "[$label] testing: security" || fail "[$label] testing: security missing"
  [ -d "$TEST_DIR/tests/contract" ] && pass "[$label] testing: contract" || fail "[$label] testing: contract missing"

  # =========================================================================
  # PERFORMANCE
  # =========================================================================
  if [ "$en" = "yes" ]; then
    [ -f "$TEST_DIR/nginx/compression.conf" ] && pass "[$label] perf: compression" || fail "[$label] perf: compression missing"
  fi

  # =========================================================================
  # DEVELOPER EXPERIENCE
  # =========================================================================
  [ -d "$TEST_DIR/.vscode" ] && pass "[$label] dx: vscode" || fail "[$label] dx: vscode missing"
  [ -d "$TEST_DIR/.devcontainer" ] && pass "[$label] dx: devcontainer" || fail "[$label] dx: devcontainer missing"
  [ -f "$TEST_DIR/scripts/cli.sh" ] && pass "[$label] dx: cli" || fail "[$label] dx: cli missing"

  # =========================================================================
  # COMMIT STANDARDS
  # =========================================================================
  [ -f "$TEST_DIR/commitlint.config.js" ] && pass "[$label] commit: commitlint" || fail "[$label] commit: commitlint missing"
  [ -f "$TEST_DIR/.editorconfig" ] && pass "[$label] commit: editorconfig" || fail "[$label] commit: editorconfig missing"

  # =========================================================================
  # CONTENT VALIDATION
  # =========================================================================
  if [ "$eb" = "go" ]; then
    grep -q "healthHandler" "$TEST_DIR/backend/main.go" 2>/dev/null && pass "[$label] content: healthHandler" || fail "[$label] content: healthHandler missing"
    grep -q "TestHealth" "$TEST_DIR/backend/main_test.go" 2>/dev/null && pass "[$label] content: TestHealth" || fail "[$label] content: TestHealth missing"
  fi
  grep -q "services:" "$TEST_DIR/docker-compose.yml" 2>/dev/null && pass "[$label] content: services" || fail "[$label] content: services missing"

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

info "Testing all selection combinations (super heavy tests)..."
# inputs: Project, Backend, Frontend, CSS, DB, BackendTest, FrontendTest, Redis, Nginx, Confirm

# =========================================================================
# BACKEND VARIANTS
# =========================================================================
run_case "go"        'test-auto\n1\n1\n1\n1\n1\n1\n1\n1\nyes\n'        go postgres:16-alpine yes yes
run_case "nodejs"    'test-auto\n2\n1\n1\n1\n1\n1\n1\n1\nyes\n'        nodejs postgres:16-alpine yes yes
run_case "rust"      'test-auto\n3\n1\n1\n1\n1\n1\n1\n1\nyes\n'        rust postgres:16-alpine yes yes

# =========================================================================
# DATABASE VARIANTS
# =========================================================================
run_case "db:mysql"  'test-auto\n1\n1\n1\n2\n1\n1\n1\n1\nyes\n'        go mysql:8.0 yes yes
run_case "db:mongo"  'test-auto\n1\n1\n1\n3\n1\n1\n1\n1\nyes\n'        go mongo:7 yes yes
run_case "db:sqlite" 'test-auto\n1\n1\n1\n4\n1\n1\n1\n1\nyes\n'        go none yes yes

# =========================================================================
# REDIS/NGINX TOGGLES
# =========================================================================
run_case "no-redis"  'test-auto\n1\n1\n1\n1\n1\n1\n2\n1\nyes\n'        go postgres:16-alpine no yes
run_case "no-nginx"  'test-auto\n1\n1\n1\n1\n1\n1\n1\n2\nyes\n'        go postgres:16-alpine yes no
run_case "minimal"   'test-auto\n1\n1\n1\n1\n1\n1\n2\n2\nyes\n'        go postgres:16-alpine no no

# =========================================================================
# FRONTEND VARIANTS
# =========================================================================
run_case "frontend:react" 'test-auto\n1\n1\n2\n1\n1\n1\n1\n1\nyes\n'  go postgres:16-alpine yes yes
run_case "frontend:vue"   'test-auto\n1\n1\n3\n1\n1\n1\n1\n1\nyes\n'  go postgres:16-alpine yes yes

echo ""
echo "========================================"
echo -e "  Cases: $CASES total, $CASE_FAIL failed"
echo -e "  Checks: ${GREEN}$PASS passed${RESET}, ${RED}$FAIL failed${RESET}, Total: $TOTAL"
echo "========================================"
[ "$FAIL" -eq 0 ] && echo -e "${GREEN}All tests passed!${RESET}" || echo -e "${RED}Some checks failed.${RESET}"
[ "$FAIL" -eq 0 ]
