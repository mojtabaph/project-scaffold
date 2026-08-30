#!/bin/bash
# lib/linting.sh - Linting configuration for all stacks

generate_linting() {
  info "Linting configuration"

  # Backend linting
  case $BACKEND in
    go)
      cat > "$PROJECT_PATH/backend/.golangci.yml" << 'EOF'
run:
  timeout: 5m

linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - unused
    - gofmt
    - goimports
    - misspell

linters-settings:
  govet:
    check-shadowing: true
  gofmt:
    simplify: true
EOF
      log "backend/.golangci.yml"
      ;;

    nodejs)
      cat > "$PROJECT_PATH/backend/.eslintrc.js" << 'EOF'
module.exports = {
  env: {
    node: true,
    es2021: true,
    jest: true,
  },
  extends: ['eslint:recommended'],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  rules: {
    'no-unused-vars': 'warn',
    'no-console': 'warn',
    'prefer-const': 'error',
    'no-var': 'error',
  },
};
EOF
      log "backend/.eslintrc.js"

      cat > "$PROJECT_PATH/backend/.prettierrc" << 'EOF'
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2
}
EOF
      log "backend/.prettierrc"
      ;;

    rust)
      cat > "$PROJECT_PATH/backend/clippy.toml" << 'EOF'
msrv = "1.75"
too-many-arguments-threshold = 10
type-complexity-threshold = 500
EOF
      log "backend/clippy.toml"

      cat > "$PROJECT_PATH/backend/rustfmt.toml" << 'EOF'
edition = "2021"
max_width = 100
tab_spaces = 4
use_field_init_shorthand = true
EOF
      log "backend/rustfmt.toml"
      ;;
  esac

  # Frontend linting (except Templ)
  if [ "$FRONTEND" != "templ" ]; then
    cat > "$PROJECT_PATH/frontend/.eslintrc.js" << 'EOF'
module.exports = {
  env: {
    browser: true,
    es2021: true,
    jest: true,
  },
  extends: ['eslint:recommended', 'plugin:react/recommended'],
  parserOptions: {
    ecmaFeatures: {
      jsx: true,
    },
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  rules: {
    'react/react-in-jsx-scope': 'off',
    'no-unused-vars': 'warn',
  },
};
EOF
    log "frontend/.eslintrc.js"

    cat > "$PROJECT_PATH/frontend/.prettierrc" << 'EOF'
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2
}
EOF
    log "frontend/.prettierrc"
  fi
}
