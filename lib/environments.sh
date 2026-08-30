#!/bin/bash
# lib/environments.sh - Multi-environment support

generate_environments() {
  info "Multi-environment configuration"

  # Development environment
  cat > "$PROJECT_PATH/.env.development" << 'EOF'
# Development Environment
APP_ENV=development
APP_DEBUG=true
LOG_LEVEL=debug

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp_dev
DB_USER=admin
DB_PASSWORD=devpassword123

# Backend
BACKEND_PORT=8080
CORS_ORIGIN=http://localhost:3000

# Frontend
FRONTEND_PORT=3000
NEXT_PUBLIC_API_URL=http://localhost:8080

# Redis
REDIS_URL=redis://localhost:6379
EOF
  log ".env.development"

  # Staging environment
  cat > "$PROJECT_PATH/.env.staging" << 'EOF'
# Staging Environment
APP_ENV=staging
APP_DEBUG=false
LOG_LEVEL=info

# Database
DB_HOST=staging-db.example.com
DB_PORT=5432
DB_NAME=myapp_staging
DB_USER=staging_user
DB_PASSWORD=${STAGING_DB_PASSWORD}

# Backend
BACKEND_PORT=8080
CORS_ORIGIN=https://staging.example.com

# Frontend
FRONTEND_PORT=3000
NEXT_PUBLIC_API_URL=https://staging-api.example.com

# Redis
REDIS_URL=redis://staging-redis.example.com:6379
EOF
  log ".env.staging"

  # Production environment
  cat > "$PROJECT_PATH/.env.production" << 'EOF'
# Production Environment
APP_ENV=production
APP_DEBUG=false
LOG_LEVEL=warn

# Database
DB_HOST=prod-db.example.com
DB_PORT=5432
DB_NAME=myapp_prod
DB_USER=prod_user
DB_PASSWORD=${PROD_DB_PASSWORD}

# Backend
BACKEND_PORT=8080
CORS_ORIGIN=https://example.com

# Frontend
FRONTEND_PORT=3000
NEXT_PUBLIC_API_URL=https://api.example.com

# Redis
REDIS_URL=redis://prod-redis.example.com:6379
EOF
  log ".env.production"

  # Docker Compose overrides
  cat > "$PROJECT_PATH/docker-compose.dev.yml" << 'EOF'
# Development overrides
services:
  backend:
    volumes:
      - ./backend:/app
    command: go run main.go
    environment:
      - APP_DEBUG=true
      - LOG_LEVEL=debug

  frontend:
    volumes:
      - ./frontend:/app
    command: npm run dev
EOF
  log "docker-compose.dev.yml"

  # Feature flags (Node.js only)
  if [ "$BACKEND" = "nodejs" ]; then
    cat > "$PROJECT_PATH/backend/feature-flags.js" << 'EOF'
const flags = {
  NEW_DASHBOARD: process.env.FF_NEW_DASHBOARD === 'true',
  BETA_FEATURES: process.env.FF_BETA_FEATURES === 'true',
  MAINTENANCE_MODE: process.env.FF_MAINTENANCE === 'true',
};

const isFeatureEnabled = (flagName) => {
  return flags[flagName] || false;
};

module.exports = { flags, isFeatureEnabled };
EOF
    log "backend/feature-flags.js"
  fi
}
