#!/bin/bash
# lib/dx.sh - Developer Experience improvements

generate_dx() {
  info "Developer Experience (DX)"

  # VS Code configuration
  mkdir -p "$PROJECT_PATH/.vscode"
  cat > "$PROJECT_PATH/.vscode/settings.json" << 'EOF'
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "go.useLanguageServer": true,
  "go.lintTool": "golangci-lint",
  "rust-analyzer.checkOnSave.command": "clippy"
}
EOF
  log ".vscode/settings.json"

  cat > "$PROJECT_PATH/.vscode/extensions.json" << 'EOF'
{
  "recommendations": [
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "golang.go",
    "rust-lang.rust-analyzer",
    "ms-vscode.vscode-typescript-next"
  ]
}
EOF
  log ".vscode/extensions.json"

  # DevContainer
  mkdir -p "$PROJECT_PATH/.devcontainer"
  cat > "$PROJECT_PATH/.devcontainer/devcontainer.json" << 'EOF'
{
  "name": "Development",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/go:1": {},
    "ghcr.io/devcontainers/features/node:1": {},
    "ghcr.io/devcontainers/features/rust:1": {}
  },
  "forwardPorts": [3000, 8080],
  "postCreateCommand": "npm install"
}
EOF
  log ".devcontainer/devcontainer.json"

  # CLI tool
  cat > "$PROJECT_PATH/scripts/cli.sh" << 'EOF'
#!/bin/bash
# Project CLI Tool
set -euo pipefail

case "$1" in
  dev)
    echo "Starting development environment..."
    docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
    ;;
  build)
    echo "Building all services..."
    docker compose build
    ;;
  test)
    echo "Running tests..."
    docker compose exec backend go test ./...
    ;;
  logs)
    docker compose logs -f
    ;;
  *)
    echo "Usage: $0 {dev|build|test|logs}"
    exit 1
    ;;
esac
EOF
  chmod +x "$PROJECT_PATH/scripts/cli.sh"
  log "scripts/cli.sh"
}
