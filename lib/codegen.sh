#!/bin/bash
# lib/codegen.sh - Code generation CLI

generate_codegen() {
  info "Code generation CLI"

  mkdir -p "$PROJECT_PATH/scripts"

  cat > "$PROJECT_PATH/scripts/generate.sh" << 'OUTER_EOF'
#!/bin/bash
# Code Generation CLI
set -euo pipefail

usage() {
  echo "Usage: $0 <command> <name>"
  echo ""
  echo "Commands:"
  echo "  model <name>       Generate a new model"
  echo "  controller <name>  Generate a new controller"
  echo "  crud <name>        Generate full CRUD"
  echo "  test <name>        Generate tests"
}

if [ $# -lt 2 ]; then
  usage
  exit 1
fi

command="$1"
name="$2"
lower_name=$(echo "$name" | tr '[:upper:]' '[:lower:]')

case "$command" in
  model)
    mkdir -p backend/models
    cat > "backend/models/${lower_name}.go" << EOF
package models

type ${name} struct {
    ID   uint   \\\`json:"id"\\\`
    Name string \\\`json:"name"\\\`
}
EOF
    echo "Created: backend/models/${lower_name}.go"
    ;;

  controller)
    mkdir -p backend/controllers
    cat > "backend/controllers/${lower_name}.go" << EOF
package controllers

import "net/http"

func Get${name}(w http.ResponseWriter, r *http.Request) {
    // TODO: Implement
}
EOF
    echo "Created: backend/controllers/${lower_name}.go"
    ;;

  crud)
    $0 model "$name"
    $0 controller "$name"
    $0 test "$name"
    echo "CRUD generated for $name"
    ;;

  test)
    mkdir -p backend/tests
    cat > "backend/tests/${lower_name}_test.go" << EOF
package tests

import "testing"

func TestGet${name}(t *testing.T) {
    // TODO: Implement
}
EOF
    echo "Created: backend/tests/${lower_name}_test.go"
    ;;

  *)
    usage
    exit 1
    ;;
esac
OUTER_EOF
  chmod +x "$PROJECT_PATH/scripts/generate.sh"
  log "scripts/generate.sh"
}
