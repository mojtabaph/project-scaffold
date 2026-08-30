#!/bin/bash
# lib/config.sh - Interactive configuration prompts

prompt_config() {
  info "Project configuration"
  echo -e "${YELLOW}----------------------------------------------${NC}"

  # Project name
  read -p "Project name (default: test): " PROJECT_NAME
  PROJECT_NAME=${PROJECT_NAME:-test}
  PROJECT_NAME=$(echo "$PROJECT_NAME" | tr -d ' ' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g')
  CRATE=$(echo "$PROJECT_NAME" | tr '-' '_')
  PROJECT_PATH="$(pwd)/$PROJECT_NAME"

  # Backend
  echo -e "\n${YELLOW}Backend Technology:${NC}"
  echo "  1) Go (recommended)"
  echo "  2) Node.js (Express)"
  echo "  3) Rust"
  read -p "Select (default: 1 - Go): " BACKEND_CHOICE
  case ${BACKEND_CHOICE:-1} in
    1) BACKEND="go" ;;
    2) BACKEND="nodejs" ;;
    3) BACKEND="rust" ;;
    *) BACKEND="go" ;;
  esac

  # Frontend
  echo -e "\n${YELLOW}Frontend Technology:${NC}"
  echo "  1) Next.js (recommended)"
  echo "  2) React (Vite)"
  echo "  3) Vue (Vite)"
  echo "  4) Angular"
  echo "  5) Svelte (Vite)"
  echo "  6) Templ + htmx (Go, SSR)"
  read -p "Select (default: 1 - Next.js): " FRONTEND_CHOICE
  case ${FRONTEND_CHOICE:-1} in
    1) FRONTEND="nextjs" ;;
    2) FRONTEND="react" ;;
    3) FRONTEND="vue" ;;
    4) FRONTEND="angular" ;;
    5) FRONTEND="svelte" ;;
    6) FRONTEND="templ" ;;
    *) FRONTEND="nextjs" ;;
  esac

  # CSS Framework
  echo -e "\n${YELLOW}CSS Framework:${NC}"
  echo "  1) Tailwind CSS (recommended)"
  echo "  2) Bootstrap"
  echo "  3) Material UI"
  echo "  4) Chakra UI"
  echo "  5) Ant Design"
  read -p "Select (default: 1 - Tailwind): " CSS_CHOICE
  case ${CSS_CHOICE:-1} in
    1) CSS_FW="tailwind" ;;
    2) CSS_FW="bootstrap" ;;
    3) CSS_FW="material-ui" ;;
    4) CSS_FW="chakra-ui" ;;
    5) CSS_FW="ant-design" ;;
    *) CSS_FW="tailwind" ;;
  esac

  # Templ + htmx requires Go + Tailwind
  if [ "$FRONTEND" = "templ" ]; then
    if [ "$BACKEND" != "go" ]; then
      warn "Templ + htmx only works with Go backend - backend changed to Go"
      BACKEND="go"
    fi
    if [ "$CSS_FW" != "tailwind" ]; then
      warn "Templ + htmx requires Tailwind CSS - CSS changed to Tailwind"
      CSS_FW="tailwind"
    fi
  fi

  # Database
  echo -e "\n${YELLOW}Database:${NC}"
  echo "  1) PostgreSQL (recommended)"
  echo "  2) MySQL"
  echo "  3) MongoDB"
  echo "  4) SQLite (no Docker DB)"
  read -p "Select (default: 1 - PostgreSQL): " DB_CHOICE
  case ${DB_CHOICE:-1} in
    1) DB="postgres"; DB_IMAGE="postgres:16-alpine"; DB_PORT="5432" ;;
    2) DB="mysql"; DB_IMAGE="mysql:8.0"; DB_PORT="3306" ;;
    3) DB="mongodb"; DB_IMAGE="mongo:7"; DB_PORT="27017" ;;
    4) DB="sqlite"; DB_IMAGE=""; DB_PORT="" ;;
    *) DB="postgres"; DB_IMAGE="postgres:16-alpine"; DB_PORT="5432" ;;
  esac

  # Database URL
  case $DB in
    postgres) DB_URL="postgresql://admin:password123@db:5432/$PROJECT_NAME" ;;
    mysql)    DB_URL="mysql://admin:password123@db:3306/$PROJECT_NAME" ;;
    mongodb)  DB_URL="mongodb://admin:password123@db:27017/$PROJECT_NAME" ;;
    sqlite)   DB_URL="sqlite://./state/$PROJECT_NAME.db" ;;
  esac

  # Testing
  echo -e "\n${YELLOW}Backend Testing:${NC}"
  echo "  1) go test (Go built-in)"
  echo "  2) Jest (Node.js)"
  echo "  3) Mocha (Node.js)"
  echo "  4) None"
  read -p "Select (default: based on backend): " TEST_CHOICE
  case ${TEST_CHOICE:-1} in
    1) TESTING="go test" ;;
    2) TESTING="jest" ;;
    3) TESTING="mocha" ;;
    4) TESTING="none" ;;
    *) TESTING="" ;;
  esac

  # Frontend Testing
  echo -e "\n${YELLOW}Frontend Testing:${NC}"
  echo "  1) Jest (recommended)"
  echo "  2) Vitest"
  echo "  3) None"
  read -p "Select (default: 1 - Jest): " FE_TEST_CHOICE
  case ${FE_TEST_CHOICE:-1} in
    1) FRONTEND_TESTING="jest" ;;
    2) FRONTEND_TESTING="vitest" ;;
    3) FRONTEND_TESTING="none" ;;
    *) FRONTEND_TESTING="jest" ;;
  esac

  # Redis
  echo -e "\n${YELLOW}Redis:${NC}"
  echo "  1) Yes (recommended)"
  echo "  2) No"
  read -p "Select (default: 1 - Yes): " REDIS_CHOICE
  case ${REDIS_CHOICE:-1} in
    1) USE_REDIS="yes" ;;
    2) USE_REDIS="no" ;;
    *) USE_REDIS="yes" ;;
  esac

  # Nginx
  echo -e "\n${YELLOW}Nginx (reverse proxy):${NC}"
  echo "  1) Yes (recommended)"
  echo "  2) No"
  read -p "Select (default: 1 - Yes): " NGINX_CHOICE
  case ${NGINX_CHOICE:-1} in
    1) USE_NGINX="yes" ;;
    2) USE_NGINX="no" ;;
    *) USE_NGINX="yes" ;;
  esac

  # Auto-set testing defaults
  if [ -z "$TESTING" ]; then
    case $BACKEND in
      go)     TESTING="go test" ;;
      nodejs) TESTING="jest" ;;
      rust)   TESTING="cargo test" ;;
    esac
  fi
}

print_summary() {
  echo -e "\n${CYAN}----------------------------------------------${NC}"
  echo -e "${GREEN}CONFIGURATION SUMMARY${NC}"
  echo -e "${CYAN}----------------------------------------------${NC}"
  echo -e "  ${BLUE}Project:${NC}   $PROJECT_NAME"
  echo -e "  ${BLUE}Backend:${NC}   $BACKEND"
  echo -e "  ${BLUE}Frontend:${NC}  $FRONTEND ($CSS_FW)"
  echo -e "  ${BLUE}Database:${NC}  $DB"
  echo -e "  ${BLUE}Testing:${NC}   $TESTING (backend) / $FRONTEND_TESTING (frontend)"
  echo -e "  ${BLUE}Redis:${NC}     $USE_REDIS"
  echo -e "  ${BLUE}Nginx:${NC}     $USE_NGINX"
  echo -e "  ${BLUE}Location:${NC}  $PROJECT_PATH\n"

  read -p "Proceed with creation? (yes/no): " CONFIRM
  if [ "$CONFIRM" != "yes" ]; then
    echo -e "\n${RED}[X] Cancelled${NC}\n"
    exit 1
  fi
}
