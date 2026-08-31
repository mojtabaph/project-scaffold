#!/bin/bash
# lib/scripts.sh - Deploy and backup script generation

generate_deploy_script() {
  info "Deploy script"

  cat > "$PROJECT_PATH/scripts/deploy.sh" << 'DEPLOYEOF'
#!/bin/bash
set -euo pipefail

# ============================================================
#  DEPLOY SCRIPT - Multi-Method
#  Usage: bash scripts/deploy.sh [method] [options]
#
#  Methods:
#    git                           - Git Pull from remote
#    scp <user>@<host> <path>      - SCP copy to server
#    rsync <user>@<host> <path>    - Rsync smart copy
#    docker <registry> <image>     - Docker push/pull
#    ci                            - Generate CI/CD config
#    local                         - Local deploy only (no transfer)
#
#  Examples:
#    bash scripts/deploy.sh local
#    bash scripts/deploy.sh git
#    bash scripts/deploy.sh scp deploy@192.168.1.100 /app
#    bash scripts/deploy.sh rsync deploy@192.168.1.100 /app
#    bash scripts/deploy.sh docker registry.example.com/myapp myapp
#    bash scripts/deploy.sh ci
# ============================================================

ENV_FILE="${ENV_FILE:-.env.production}"
COMPOSE_FILE="docker-compose.prod.yml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
  echo ""
  echo -e "${CYAN}=========================================${NC}"
  echo -e "${CYAN}  DEPLOY - $1${NC}"
  echo -e "${CYAN}=========================================${NC}"
  echo ""
}

print_step() {
  echo -e "${YELLOW}[$1/$2]${NC} $3"
}

print_success() {
  echo -e "${GREEN}  [OK]${NC} $1"
}

print_error() {
  echo -e "${RED}  [ERROR]${NC} $1"
}

# ============================================================
#  UPDATE .env.production
# ============================================================
update_env() {
  local key="$1"
  local value="$2"
  if [ -f "$ENV_FILE" ]; then
    if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
      sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
    else
      echo "${key}=${value}" >> "$ENV_FILE"
    fi
  fi
}

# ============================================================
#  METHOD SELECTION (Interactive with default from .env)
# ============================================================
select_method() {
  # Read default from .env.production
  DEFAULT_METHOD="local"
  if [ -f "$ENV_FILE" ]; then
    ENV_METHOD=$(grep -E "^DEPLOY_METHOD=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || true)
    if [ -n "$ENV_METHOD" ]; then
      DEFAULT_METHOD="$ENV_METHOD"
    fi
  fi

  # Map default to number
  case "$DEFAULT_METHOD" in
    git)   DEFAULT_NUM="1" ;;
    scp)   DEFAULT_NUM="2" ;;
    rsync) DEFAULT_NUM="3" ;;
    docker) DEFAULT_NUM="4" ;;
    ci)    DEFAULT_NUM="5" ;;
    local) DEFAULT_NUM="6" ;;
    *)     DEFAULT_NUM="6" ;;
  esac

  print_header "Select Deployment Method"
  echo "  1) Git Pull        - Pull from GitHub/GitLab"
  echo "  2) SCP             - Copy to server via SSH"
  echo "  3) Rsync           - Smart copy (only changes)"
  echo "  4) Docker Push/Pull - Via container registry"
  echo "  5) CI/CD           - Generate GitHub Actions"
  echo "  6) Local           - Deploy on this server only"
  echo ""
  read -p "  Select method [$DEFAULT_METHOD]: " choice

  # If empty, use default
  choice="${choice:-$DEFAULT_NUM}"

  case $choice in
    1) METHOD="git" ;;
    2) METHOD="scp" ;;
    3) METHOD="rsync" ;;
    4) METHOD="docker" ;;
    5) METHOD="ci" ;;
    6) METHOD="local" ;;
    *)
      echo -e "${RED}Invalid choice${NC}"
      exit 1
      ;;
  esac

  # Save to .env.production
  update_env "DEPLOY_METHOD" "$METHOD"
}

# ============================================================
#  METHOD 1: Git Pull
# ============================================================
deploy_git() {
  print_header "Deploy via Git Pull"

  # Check if git repo
  if [ ! -d ".git" ]; then
    print_error "Not a git repository"
    exit 1
  fi

  print_step 1 4 "Pulling latest code..."
  git pull origin main

  print_step 2 4 "Installing dependencies..."
  if [ -f "backend/go.mod" ]; then
    (cd backend && go mod download) || true
  elif [ -f "backend/package.json" ]; then
    (cd backend && npm ci --production) || true
  fi

  print_step 3 4 "Building Docker images..."
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" build

  print_step 4 4 "Starting services..."
  deploy_local_services
}

# ============================================================
#  METHOD 2: SCP
# ============================================================
deploy_scp() {
  print_header "Deploy via SCP"

  if [ -z "$SCP_HOST" ] || [ -z "$SCP_PATH" ]; then
    echo "  Usage: bash scripts/deploy.sh scp <user>@<host> <path>"
    echo "  Example: bash scripts/deploy.sh scp deploy@192.168.1.100 /app"
    exit 1
  fi

  print_step 1 3 "Copying files to $SCP_HOST..."
  rsync -avz --delete \
    --exclude 'node_modules' \
    --exclude '.git' \
    --exclude '*.log' \
    --exclude 'backups' \
    --exclude 'uploads' \
    ./ "$SCP_HOST:$SCP_PATH/"

  print_step 2 3 "Running remote deploy..."
  ssh "$SCP_HOST" "cd $SCP_PATH && bash scripts/deploy.sh local"

  print_step 3 3 "Deploy complete on remote server"
}

# ============================================================
#  METHOD 3: Rsync
# ============================================================
deploy_rsync() {
  print_header "Deploy via Rsync"

  if [ -z "$RSYNC_HOST" ] || [ -z "$RSYNC_PATH" ]; then
    echo "  Usage: bash scripts/deploy.sh rsync <user>@<host> <path>"
    echo "  Example: bash scripts/deploy.sh rsync deploy@192.168.1.100 /app"
    exit 1
  fi

  print_step 1 4 "Syncing files to $RSYNC_HOST..."
  rsync -avz --delete \
    --exclude 'node_modules' \
    --exclude '.git' \
    --exclude '*.log' \
    --exclude 'backups' \
    --exclude 'uploads' \
    --exclude '.env' \
    ./ "$RSYNC_HOST:$RSYNC_PATH/"

  print_step 2 4 "Setting permissions..."
  ssh "$RSYNC_HOST" "chmod +x $RSYNC_PATH/scripts/*.sh"

  print_step 3 4 "Running remote deploy..."
  ssh "$RSYNC_HOST" "cd $RSYNC_PATH && bash scripts/deploy.sh local"

  print_step 4 4 "Deploy complete on remote server"
}

# ============================================================
#  METHOD 4: Docker Push/Pull
# ============================================================
deploy_docker() {
  print_header "Deploy via Docker Registry"

  if [ -z "$DOCKER_REGISTRY" ]; then
    echo "  Usage: bash scripts/deploy.sh docker <registry> [image]"
    echo "  Example: bash scripts/deploy.sh docker registry.example.com/myapp myapp"
    exit 1
  fi

  DOCKER_IMAGE="${DOCKER_IMAGE:-myapp}"
  DOCKER_TAG="${DOCKER_TAG:-latest}"
  FULL_IMAGE="$DOCKER_REGISTRY/$DOCKER_IMAGE:$DOCKER_TAG"

  print_step 1 4 "Building Docker image..."
  docker build -t "$FULL_IMAGE" .

  print_step 2 4 "Pushing to registry..."
  docker push "$FULL_IMAGE"

  print_step 3 4 "Pulling on remote server..."
  ssh "$DEPLOY_HOST" "docker pull $FULL_IMAGE" 2>/dev/null || true

  print_step 4 4 "Deploy complete"
  echo ""
  echo "  Image: $FULL_IMAGE"
  echo "  Run on server: docker compose up -d"
}

# ============================================================
#  METHOD 5: CI/CD (Generate GitHub Actions)
# ============================================================
deploy_ci() {
  print_header "Generate CI/CD Pipeline"

  mkdir -p .github/workflows

  cat > .github/workflows/deploy.yml << 'CIEOF'
name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  APP_NAME: myapp
  DEPLOY_HOST: ${{ secrets.DEPLOY_HOST }}
  DEPLOY_USER: ${{ secrets.DEPLOY_USER }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.23'
      - name: Run tests
        run: |
          cd backend && go test ./...

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Setup SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/deploy_key
          chmod 600 ~/.ssh/deploy_key
          ssh-keyscan -H ${{ env.DEPLOY_HOST }} >> ~/.ssh/known_hosts

      - name: Deploy via Rsync
        run: |
          rsync -avz --delete \
            --exclude 'node_modules' \
            --exclude '.git' \
            --exclude '*.log' \
            -e "ssh -i ~/.ssh/deploy_key" \
            ./ ${{ env.DEPLOY_USER }}@${{ env.DEPLOY_HOST }}:/app/

      - name: Run remote deploy
        run: |
          ssh -i ~/.ssh/deploy_key ${{ env.DEPLOY_USER }}@${{ env.DEPLOY_HOST }} \
            "cd /app && bash scripts/deploy.sh local"

      - name: Cleanup SSH
        if: always()
        run: rm -f ~/.ssh/deploy_key
CIEOF

  print_success ".github/workflows/deploy.yml created"
  echo ""
  echo "  Required GitHub Secrets:"
  echo "    DEPLOY_HOST    - Server IP or hostname"
  echo "    DEPLOY_USER    - SSH username"
  echo "    SSH_PRIVATE_KEY - SSH private key"
  echo ""
  echo "  Push to main to trigger deploy!"
}

# ============================================================
#  METHOD 6: Local Deploy (No Transfer)
# ============================================================
deploy_local() {
  print_header "Local Deploy"

  print_step 1 5 "Validating environment file..."
  if [ ! -f "$ENV_FILE" ]; then
    print_error "$ENV_FILE not found!"
    echo "  Copy .env.production to .env.production and fill in values."
    exit 1
  fi
  print_success "Environment file found"

  print_step 2 5 "Building Docker images..."
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" build
  print_success "Images built"

  print_step 3 5 "Pulling base images..."
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull 2>/dev/null || true
  print_success "Base images pulled"

  print_step 4 5 "Running migrations..."
  if [ -f "scripts/migrate.sh" ]; then
    ENV_FILE="$ENV_FILE" bash scripts/migrate.sh
    print_success "Migrations complete"
  else
    print_success "No migrations needed"
  fi

  deploy_local_services
}

# ============================================================
#  Shared: Start Services
# ============================================================
deploy_local_services() {
  print_step 5 5 "Starting services..."
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

  echo ""
  echo "  Waiting for services..."
  sleep 10

  if docker compose -f "$COMPOSE_FILE" ps | grep -q "unhealthy\|starting"; then
    echo -e "  ${YELLOW}[WARN]${NC} Some services may not be healthy yet."
    docker compose -f "$COMPOSE_FILE" ps
  else
    print_success "All services are running!"
  fi

  echo ""
  echo -e "${GREEN}=========================================${NC}"
  echo -e "${GREEN}  Deploy complete!${NC}"
  echo -e "${GREEN}=========================================${NC}"
}

# ============================================================
#  MAIN
# ============================================================
METHOD="${1:-}"

# Parse method arguments
case "$METHOD" in
  git)
    deploy_git
    ;;
  scp)
    SCP_HOST="${2:-}"
    SCP_PATH="${3:-}"
    deploy_scp
    ;;
  rsync)
    RSYNC_HOST="${2:-}"
    RSYNC_PATH="${3:-}"
    deploy_rsync
    ;;
  docker)
    DOCKER_REGISTRY="${2:-}"
    DOCKER_IMAGE="${3:-myapp}"
    deploy_docker
    ;;
  ci)
    deploy_ci
    ;;
  local)
    deploy_local
    ;;
  "")
    select_method
    # Read defaults from .env.production
    if [ -f "$ENV_FILE" ]; then
      DEPLOY_HOST="${DEPLOY_HOST:-$(grep -E "^DEPLOY_HOST=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || true)}"
      DEPLOY_PATH="${DEPLOY_PATH:-$(grep -E "^DEPLOY_PATH=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || true)}"
      DOCKER_REGISTRY="${DOCKER_REGISTRY:-$(grep -E "^DOCKER_REGISTRY=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || true)}"
    fi
    case "$METHOD" in
      git) deploy_git ;;
      scp)
        read -p "  Server (user@host) [$DEPLOY_HOST]: " SCP_HOST
        SCP_HOST="${SCP_HOST:-$DEPLOY_HOST}"
        read -p "  Path [$DEPLOY_PATH]: " SCP_PATH
        SCP_PATH="${SCP_PATH:-$DEPLOY_PATH}"
        update_env "DEPLOY_HOST" "$SCP_HOST"
        update_env "DEPLOY_PATH" "$SCP_PATH"
        deploy_scp
        ;;
      rsync)
        read -p "  Server (user@host) [$DEPLOY_HOST]: " RSYNC_HOST
        RSYNC_HOST="${RSYNC_HOST:-$DEPLOY_HOST}"
        read -p "  Path [$DEPLOY_PATH]: " RSYNC_PATH
        RSYNC_PATH="${RSYNC_PATH:-$DEPLOY_PATH}"
        update_env "DEPLOY_HOST" "$RSYNC_HOST"
        update_env "DEPLOY_PATH" "$RSYNC_PATH"
        deploy_rsync
        ;;
      docker)
        read -p "  Registry [$DOCKER_REGISTRY]: " DOCKER_REGISTRY
        DOCKER_REGISTRY="${DOCKER_REGISTRY:-$DOCKER_REGISTRY}"
        update_env "DOCKER_REGISTRY" "$DOCKER_REGISTRY"
        deploy_docker
        ;;
      ci) deploy_ci ;;
      local) deploy_local ;;
    esac
    ;;
  *)
    echo "Usage: bash scripts/deploy.sh [method] [options]"
    echo ""
    echo "Methods:"
    echo "  local                     - Deploy on this server"
    echo "  git                       - Deploy via git pull"
    echo "  scp <user>@<host> <path>  - Deploy via SCP"
    echo "  rsync <user>@<host> <path> - Deploy via Rsync"
    echo "  docker <registry> [image] - Deploy via Docker registry"
    echo "  ci                        - Generate CI/CD config"
    exit 1
    ;;
esac
DEPLOYEOF
  chmod +x "$PROJECT_PATH/scripts/deploy.sh"
  log "scripts/deploy.sh"
}

generate_backup_script() {
  info "Backup script"

  cat > "$PROJECT_PATH/scripts/backup.sh" << 'BACKUPEOF'
#!/bin/bash
set -euo pipefail

# ============================================================
#  BACKUP SCRIPT
#  Usage: bash scripts/backup.sh [db_type]
#  db_type: postgres (default), mysql, mongodb
# ============================================================

DB_TYPE="${1:-postgres}"
BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP"
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"

echo "========================================="
echo "  Backup: $DB_TYPE"
echo "========================================="

case $DB_TYPE in
  postgres)
    echo "Backing up PostgreSQL..."
    if command -v pg_dump &> /dev/null; then
      docker exec -t $(docker ps -q -f name=db) pg_dump -U admin -d ${DB_NAME:-myapp} | gzip > "$BACKUP_FILE.sql.gz"
    else
      docker exec -t $(docker ps -q -f name=db) pg_dump -U admin -d ${DB_NAME:-myapp} | gzip > "$BACKUP_FILE.sql.gz"
    fi
    ;;
  mysql)
    echo "Backing up MySQL..."
    docker exec -t $(docker ps -q -f name=db) mysqldump -u admin -p${DB_PASSWORD:-password123} ${DB_NAME:-myapp} | gzip > "$BACKUP_FILE.sql.gz"
    ;;
  mongodb)
    echo "Backing up MongoDB..."
    docker exec -t $(docker ps -q -f name=db) mongodump --archive | gzip > "$BACKUP_FILE.archive.gz"
    ;;
  *)
    echo "Error: Unknown DB type '$DB_TYPE'"
    echo "Usage: bash scripts/backup.sh [postgres|mysql|mongodb]"
    exit 1
    ;;
esac

# Check if backup was created
if [ -f "$BACKUP_FILE.sql.gz" ] || [ -f "$BACKUP_FILE.archive.gz" ]; then
  BACKUP_SIZE=$(ls -lh "$BACKUP_FILE"* | awk '{print $5}')
  echo "Backup created: $BACKUP_FILE ($BACKUP_SIZE)"
else
  echo "Error: Backup failed!"
  exit 1
fi

# Cleanup old backups
echo ""
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "backup_*" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

# List remaining backups
echo ""
echo "Existing backups:"
ls -lh "$BACKUP_DIR"/backup_* 2>/dev/null | awk '{print $9, $5}'

echo ""
echo "========================================="
echo "  Backup complete!"
echo "========================================="
BACKUPEOF
  chmod +x "$PROJECT_PATH/scripts/backup.sh"
  log "scripts/backup.sh"
}

generate_restore_script() {
  info "Restore script"

  cat > "$PROJECT_PATH/scripts/restore.sh" << 'RESTOREEOF'
#!/bin/bash
set -euo pipefail

# ============================================================
#  RESTORE SCRIPT
#  Usage: bash scripts/restore.sh <backup_file> [db_type]
#  Example: bash scripts/restore.sh backups/backup_20240101_120000.sql.gz postgres
# ============================================================

BACKUP_FILE="${1:-}"
DB_TYPE="${2:-postgres}"

if [ -z "$BACKUP_FILE" ]; then
  echo "Usage: bash scripts/restore.sh <backup_file> [db_type]"
  echo "Example: bash scripts/restore.sh backups/backup_20240101_120000.sql.gz postgres"
  exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: Backup file '$BACKUP_FILE' not found!"
  exit 1
fi

echo "========================================="
echo "  Restore from: $BACKUP_FILE"
echo "  Database type: $DB_TYPE"
echo "========================================="
echo ""
echo "WARNING: This will overwrite the current database!"
read -p "Are you sure? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Restore cancelled."
  exit 0
fi

case $DB_TYPE in
  postgres)
    echo "Restoring PostgreSQL..."
    gunzip -c "$BACKUP_FILE" | docker exec -i $(docker ps -q -f name=db) psql -U admin -d ${DB_NAME:-myapp}
    ;;
  mysql)
    echo "Restoring MySQL..."
    gunzip -c "$BACKUP_FILE" | docker exec -i $(docker ps -q -f name=db) mysql -u admin -p${DB_PASSWORD:-password123} ${DB_NAME:-myapp}
    ;;
  mongodb)
    echo "Restoring MongoDB..."
    gunzip -c "$BACKUP_FILE" | docker exec -i $(docker ps -q -f name=db) mongorestore --archive
    ;;
  *)
    echo "Error: Unknown DB type '$DB_TYPE'"
    exit 1
    ;;
esac

echo ""
echo "========================================="
echo "  Restore complete!"
echo "========================================="
RESTOREEOF
  chmod +x "$PROJECT_PATH/scripts/restore.sh"
  log "scripts/restore.sh"
}
