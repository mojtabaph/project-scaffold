#!/bin/bash
# lib/docker.sh - Docker Compose and root files generation

generate_root_files() {
  info "Root files"

  # .env.example
  cat > "$PROJECT_PATH/.env.example" << EOF
# Database
DB_NAME=$PROJECT_NAME
DB_USER=admin
DB_PASSWORD=change_me_in_production
DB_PORT=$DB_PORT
DATABASE_URL=$DB_URL

# Backend
BACKEND_PORT=8080
ENVIRONMENT=development

# Frontend
FRONTEND_PORT=3000
NEXT_PUBLIC_API_URL=http://localhost:8080
EOF
  if [ "$USE_REDIS" = "yes" ]; then
    cat >> "$PROJECT_PATH/.env.example" << EOF

# Redis
REDIS_URL=redis://redis:6379
EOF
  fi
  log ".env.example"

  # .gitignore
  cat > "$PROJECT_PATH/.gitignore" << 'EOF'
.env
.env.local
node_modules/
.next/
dist/
build/
*.log
.DS_Store
.vscode/
.idea/
data/
state/*.db
state/project_state.db
*.db
EOF
  log ".gitignore"

  # scripts/test.sh
  cat > "$PROJECT_PATH/scripts/test.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

echo "Running tests..."
FAILED=0

# Backend tests
if [ -d "backend" ]; then
  echo ""
  echo "=== Backend Tests ==="
  if [ -f "backend/go.mod" ]; then
    echo "Running Go tests..."
    (cd backend && go test -v ./...) || FAILED=$((FAILED+1))
  elif [ -f "backend/package.json" ]; then
    echo "Running Node.js tests..."
    (cd backend && npm test) || FAILED=$((FAILED+1))
  elif [ -f "backend/Cargo.toml" ]; then
    echo "Running Rust tests..."
    (cd backend && cargo test) || FAILED=$((FAILED+1))
  fi
fi

# Frontend tests
if [ -d "frontend" ]; then
  echo ""
  echo "=== Frontend Tests ==="
  if [ -f "frontend/package.json" ]; then
    if grep -q '"test"' frontend/package.json; then
      echo "Running frontend tests..."
      (cd frontend && npm test) || FAILED=$((FAILED+1))
    fi
  fi
fi

echo ""
if [ $FAILED -eq 0 ]; then
  echo "All tests passed!"
  exit 0
else
  echo "Some tests failed!"
  exit 1
fi
EOF
  chmod +x "$PROJECT_PATH/scripts/test.sh"
  log "scripts/test.sh"

  # Makefile
  cat > "$PROJECT_PATH/Makefile" << 'EOF'
.PHONY: help dev build up down logs ps test lint format clean migrate seed backup restore memory

help:
	@echo "Available commands:"
	@echo "  make dev       - Build and start all services"
	@echo "  make build     - Build all Docker images"
	@echo "  make up        - Start services in background"
	@echo "  make down      - Stop services"
	@echo "  make logs      - View service logs"
	@echo "  make ps        - Show service status"
	@echo "  make test      - Run all tests (scripts/test.sh)"
	@echo "  make lint      - Run linters"
	@echo "  make format    - Run formatters"
	@echo "  make clean     - Stop and remove all containers/data"
	@echo "  make migrate   - Run database migrations"
	@echo "  make seed      - Seed database"
	@echo "  make backup    - Backup database"
	@echo "  make restore   - Restore database from backup"
	@echo "  make memory    - Show AI memory state"

dev:
	docker compose up -d --build

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

ps:
	docker compose ps

test:
	bash scripts/test.sh

lint:
	@if [ -d backend ] && [ -f backend/go.mod ]; then (cd backend && go vet ./...); fi
	@if [ -d frontend ] && [ -f frontend/package.json ]; then (cd frontend && npx eslint . --ext .js,.jsx,.ts,.tsx,.vue --max-warnings 0); fi

format:
	@if [ -d backend ] && [ -f backend/go.mod ]; then (cd backend && gofmt -w .); fi
	@if [ -d frontend ] && [ -f frontend/package.json ]; then (cd frontend && npx prettier --write .); fi

clean:
	docker compose down -v
	@rm -rf backend/node_modules frontend/node_modules 2>/dev/null || true

migrate:
	bash scripts/migrate.sh

seed:
	bash scripts/migrate.sh --seed

backup:
	bash scripts/backup.sh

restore:
	@echo "Usage: make restore file=backups/backup_TIMESTAMP.sql.gz"
	bash scripts/restore.sh $(file)

memory:
	bash scripts/memory-read.sh
EOF
  log "Makefile"

  # brief/README.md
  mkdir -p "$PROJECT_PATH/brief"
  cat > "$PROJECT_PATH/brief/README.md" << 'EOF'
# Brief

Project brief and requirements go here.
EOF
  log "brief/README.md"

  # STACK.md
  cat > "$PROJECT_PATH/STACK.md" << EOF
# Stack Configuration

Generated: \$(date '+%Y-%m-%d %H:%M:%S')

## Selections

| Component | Choice |
|-----------|--------|
| Backend | $BACKEND |
| Frontend | $FRONTEND |
| CSS Framework | $CSS_FW |
| Database | $DB |
| Redis | $USE_REDIS |
| Nginx | $USE_NGINX |
| Backend Testing | $TESTING |
| Frontend Testing | $FRONTEND_TESTING |
EOF
  log "STACK.md"
}

generate_nginx() {
  if [ "$USE_NGINX" != "yes" ]; then
    return
  fi

  info "Nginx configuration"

  cat > "$PROJECT_PATH/nginx/nginx.conf" << 'NGINXEOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    sendfile    on;
    keepalive_timeout  65;

    gzip  on;
    gzip_types text/plain text/css application/json application/javascript text/xml;

    upstream backend {
        server backend:8080;
    }
NGINXEOF

  if [ "$FRONTEND" != "templ" ]; then
    cat >> "$PROJECT_PATH/nginx/nginx.conf" << 'NGINXEOF'

    upstream frontend {
        server frontend:3000;
    }
NGINXEOF
  fi

  cat >> "$PROJECT_PATH/nginx/nginx.conf" << 'NGINXEOF'

    server {
        listen 80;
        server_name _;

        # API routes -> backend
        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
NGINXEOF

  if [ "$FRONTEND" != "templ" ]; then
    cat >> "$PROJECT_PATH/nginx/nginx.conf" << 'NGINXEOF'

        # Frontend -> frontend service
        location / {
            proxy_pass http://frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
NGINXEOF
  fi

  cat >> "$PROJECT_PATH/nginx/nginx.conf" << 'NGINXEOF'

        # Health check
        location /nginx-health {
            return 200 'ok';
            add_header Content-Type text/plain;
        }
    }
}
NGINXEOF

  log "nginx/nginx.conf"
}

generate_docker_compose() {
  info "Docker Compose"

  # Build depends_on section
  DEPENDS_ON=""
  if [ "$DB" != "sqlite" ]; then
    DEPENDS_ON="${DEPENDS_ON}      db:\n        condition: service_healthy\n"
  fi
  if [ "$USE_REDIS" = "yes" ]; then
    DEPENDS_ON="${DEPENDS_ON}      redis:\n        condition: service_healthy\n"
  fi

  # Build environment section
  ENVIRONMENT="      - DATABASE_URL=$DB_URL\n      - DB_NAME=$PROJECT_NAME"
  if [ "$USE_REDIS" = "yes" ]; then
    ENVIRONMENT="${ENVIRONMENT}\n      - REDIS_URL=redis://redis:6379"
  fi

  cat > "$PROJECT_PATH/docker-compose.yml" << EOF
services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
$(echo -e "$ENVIRONMENT")
    depends_on:
$(echo -e "$DEPENDS_ON")
    restart: unless-stopped
EOF

  # Frontend service (only if not templ/SSR)
  if [ "$FRONTEND" != "templ" ]; then
    # Next.js container listens on 3000; Vite/Angular static containers use nginx on 80
    if [ "$FRONTEND" = "nextjs" ]; then
      FRONT_PORT_MAP="3000:3000"
    else
      FRONT_PORT_MAP="3000:80"
    fi
    cat >> "$PROJECT_PATH/docker-compose.yml" << EOF

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "$FRONT_PORT_MAP"
    depends_on:
      - backend
    restart: unless-stopped
EOF
  fi

  # Database service
  if [ "$DB" != "sqlite" ]; then
    cat >> "$PROJECT_PATH/docker-compose.yml" << EOF

  db:
    image: $DB_IMAGE
    environment:
EOF

    case $DB in
      postgres)
        cat >> "$PROJECT_PATH/docker-compose.yml" << EOF
      POSTGRES_DB: $PROJECT_NAME
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: password123
EOF
        DB_VOLUME="/var/lib/postgresql/data"
        DB_HEALTHCHECK='test: ["CMD", "pg_isready", "-U", "admin"]'
        ;;
      mysql)
        cat >> "$PROJECT_PATH/docker-compose.yml" << EOF
      MYSQL_DATABASE: $PROJECT_NAME
      MYSQL_ROOT_PASSWORD: password123
      MYSQL_USER: admin
      MYSQL_PASSWORD: password123
EOF
        DB_VOLUME="/var/lib/mysql"
        DB_HEALTHCHECK='test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]'
        ;;
      mongodb)
        cat >> "$PROJECT_PATH/docker-compose.yml" << EOF
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: password123
      MONGO_INITDB_DATABASE: $PROJECT_NAME
EOF
        DB_VOLUME="/data/db"
        DB_HEALTHCHECK='test: ["CMD", "mongosh", "--eval", "db.runCommand({ping:1}).ok"]'
        ;;
    esac

    cat >> "$PROJECT_PATH/docker-compose.yml" << EOF
    ports:
      - "$DB_PORT:$DB_PORT"
    volumes:
      - db_data:$DB_VOLUME
    healthcheck:
      $DB_HEALTHCHECK
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped
EOF
  fi

  # Redis service
  if [ "$USE_REDIS" = "yes" ]; then
    cat >> "$PROJECT_PATH/docker-compose.yml" << EOF

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped
EOF
  fi

  # Nginx service
  if [ "$USE_NGINX" = "yes" ]; then
    cat >> "$PROJECT_PATH/docker-compose.yml" << EOF

  nginx:
    image: nginx:stable-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 10s
      timeout: 5s
      retries: 3
    depends_on:
EOF
    if [ "$FRONTEND" != "templ" ]; then
      cat >> "$PROJECT_PATH/docker-compose.yml" << EOF
      frontend:
        condition: service_healthy
EOF
    fi
    cat >> "$PROJECT_PATH/docker-compose.yml" << EOF
      backend:
        condition: service_healthy
    restart: unless-stopped
EOF
  fi

  # Volumes
  if [ "$DB" != "sqlite" ]; then
    cat >> "$PROJECT_PATH/docker-compose.yml" << EOF

volumes:
  db_data:
EOF
  fi

  log "docker-compose.yml"
}
