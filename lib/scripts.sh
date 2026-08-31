#!/bin/bash
# lib/scripts.sh - Deploy and backup script generation

generate_deploy_script() {
  info "Deploy script"

  cat > "$PROJECT_PATH/scripts/deploy.sh" << 'DEPLOYEOF'
#!/bin/bash
set -euo pipefail

# ============================================================
#  DEPLOY SCRIPT
#  Usage: ENV_FILE=.env.production bash scripts/deploy.sh
# ============================================================

ENV_FILE="${ENV_FILE:-.env.production}"
COMPOSE_FILE="docker-compose.prod.yml"

echo "========================================="
echo "  Deploying with $ENV_FILE"
echo "========================================="

# 1. Validate env file
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE not found!"
  echo "Copy .env.production.example to .env.production and fill in values."
  exit 1
fi
echo "[1/5] Environment file validated"

# 2. Build images
echo "[2/5] Building Docker images..."
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" build

# 3. Pull base images
echo "[3/5] Pulling base images..."
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull

# 4. Run migrations (if migrate script exists)
if [ -f "scripts/migrate.sh" ]; then
  echo "[4/5] Running migrations..."
  ENV_FILE="$ENV_FILE" bash scripts/migrate.sh
else
  echo "[4/5] No migration script found - skipping"
fi

# 5. Start services
echo "[5/5] Starting services..."
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

# Health check
echo ""
echo "Waiting for services to be healthy..."
sleep 10

if docker compose -f "$COMPOSE_FILE" ps | grep -q "unhealthy\|starting"; then
  echo "Warning: Some services may not be healthy yet."
  docker compose -f "$COMPOSE_FILE" ps
else
  echo "All services are running!"
fi

echo ""
echo "========================================="
echo "  Deploy complete!"
echo "========================================="
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
