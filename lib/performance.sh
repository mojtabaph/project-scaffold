#!/bin/bash
# lib/performance.sh - Performance optimization

generate_performance() {
  info "Performance optimization"

  # Gzip/Brotli compression
  if [ "$USE_NGINX" = "yes" ]; then
    cat > "$PROJECT_PATH/nginx/compression.conf" << 'EOF'
# Gzip compression
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css text/xml application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;

# Brotli compression (if available)
brotli on;
brotli_comp_level 6;
brotli_types text/plain text/css application/json application/javascript text/xml application/xml+rss image/svg+xml;
EOF
    log "nginx/compression.conf"
  fi

  # Caching layer (Node.js only)
  if [ "$BACKEND" = "nodejs" ]; then
    cat > "$PROJECT_PATH/backend/cache.js" << 'EOF'
const NodeCache = require('node-cache');

const cache = new NodeCache({
  stdTTL: 600, // 10 minutes
  checkperiod: 120,
});

const getCache = (key) => {
  return cache.get(key);
};

const setCache = (key, value, ttl) => {
  cache.set(key, value, ttl);
};

const clearCache = () => {
  cache.flushAll();
};

module.exports = { getCache, setCache, clearCache };
EOF
    log "backend/cache.js"
  fi

  # CDN configuration
  cat > "$PROJECT_PATH/nginx/cdn.conf" << 'EOF'
# CDN configuration
# Static assets with long cache
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    access_log off;
}

# API responses with short cache
location /api/ {
    add_header Cache-Control "no-cache, no-store, must-revalidate";
    proxy_pass http://backend;
}
EOF
  log "nginx/cdn.conf"

  # Connection pooling (Node.js only)
  if [ "$BACKEND" = "nodejs" ]; then
    cat > "$PROJECT_PATH/backend/pool.js" << 'EOF'
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

module.exports = pool;
EOF
    log "backend/pool.js"
  fi
}
