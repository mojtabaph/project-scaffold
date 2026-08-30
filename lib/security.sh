#!/bin/bash
# lib/security.sh - Security hardening

generate_security() {
  info "Security hardening"

  # Security headers (nginx)
  if [ "$USE_NGINX" = "yes" ]; then
    cat > "$PROJECT_PATH/nginx/security-headers.conf" << 'EOF'
# Security Headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:;" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;
EOF
    log "nginx/security-headers.conf"

    # Rate limiting
    cat > "$PROJECT_PATH/nginx/rate-limit.conf" << 'EOF'
# Rate Limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;

# Apply rate limiting
location /api/ {
    limit_req zone=api burst=20 nodelay;
    proxy_pass http://backend;
}

location /api/auth/login {
    limit_req zone=login burst=3 nodelay;
    proxy_pass http://backend;
}
EOF
    log "nginx/rate-limit.conf"
  fi

  # CORS configuration (Node.js)
  if [ "$BACKEND" = "nodejs" ]; then
    cat > "$PROJECT_PATH/backend/cors.js" << 'EOF'
const cors = require('cors');

const corsOptions = {
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400,
};

module.exports = cors(corsOptions);
EOF
    log "backend/cors.js"
  fi

  # Input validation (Node.js only)
  if [ "$BACKEND" = "nodejs" ]; then
    cat > "$PROJECT_PATH/backend/validation.js" << 'EOF'
const validateEmail = (email) => {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email);
};

const validatePassword = (password) => {
  return password && password.length >= 8;
};

const sanitizeInput = (input) => {
  if (typeof input !== 'string') return input;
  return input
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;');
};

module.exports = { validateEmail, validatePassword, sanitizeInput };
EOF
    log "backend/validation.js"
  fi
}
