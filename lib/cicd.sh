#!/bin/bash
# lib/cicd.sh - GitHub Actions CI/CD

generate_cicd() {
  info "CI/CD (GitHub Actions)"

  mkdir -p "$PROJECT_PATH/.github/workflows"
  mkdir -p "$PROJECT_PATH/.github/ISSUE_TEMPLATE"

  # CI workflow
  cat > "$PROJECT_PATH/.github/workflows/ci.yml" << 'EOF'
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.23'
      - name: Lint Go
        run: golangci-lint run
        working-directory: backend

  test:
    runs-on: ubuntu-latest
    needs: lint
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: admin
          POSTGRES_PASSWORD: password123
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.23'
      - name: Run Tests
        run: go test -v ./...
        working-directory: backend
        env:
          DATABASE_URL: postgres://admin:password123@localhost:5432/testdb?sslmode=disable

  build:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - name: Build Backend
        run: docker build -t backend ./backend
      - name: Build Frontend
        run: docker build -t frontend ./frontend
EOF
  log ".github/workflows/ci.yml"

  # Deploy workflow
  cat > "$PROJECT_PATH/.github/workflows/deploy.yml" << 'EOF'
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to production
        run: |
          echo "Deploy to production server"
          # Add your deployment commands here
EOF
  log ".github/workflows/deploy.yml"

  # Issue template: bug report
  cat > "$PROJECT_PATH/.github/ISSUE_TEMPLATE/bug_report.md" << 'EOF'
---
name: Bug report
about: Create a report to help us improve
title: "[BUG] "
labels: bug
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment (please complete the following information):**
 - OS: [e.g. Ubuntu 22.04]
 - Browser: [e.g. Chrome 120]
 - Version: [e.g. 1.0.0]

**Additional context**
Add any other context about the problem here.
EOF
  log ".github/ISSUE_TEMPLATE/bug_report.md"

  # Issue template: feature request
  cat > "$PROJECT_PATH/.github/ISSUE_TEMPLATE/feature_request.md" << 'EOF'
---
name: Feature request
about: Suggest an idea for this project
title: "[FEATURE] "
labels: enhancement
assignees: ''

---

**Is your feature request related to a problem? Please describe.**
A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features you've considered.

**Additional context**
Add any other context or screenshots about the feature request here.
EOF
  log ".github/ISSUE_TEMPLATE/feature_request.md"

  # PR template
  cat > "$PROJECT_PATH/.github/PULL_REQUEST_TEMPLATE.md" << 'EOF'
## Description

Please include a summary of the change and which issue is fixed. Please also include relevant motivation and context.

Fixes # (issue)

## Type of change

Please delete options that are not relevant.

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] This change requires a documentation update

## How Has This Been Tested?

Please describe the tests that you ran to verify your changes.

- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual testing

## Checklist:

- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes

## Screenshots (if appropriate):
EOF
  log ".github/PULL_REQUEST_TEMPLATE.md"

  # config.yml for issue templates
  cat > "$PROJECT_PATH/.github/ISSUE_TEMPLATE/config.yml" << 'EOF'
blank_issues_enabled: true
contact_links:
  - name: GitHub Community Support
    url: https://github.com/orgs/community/discussions
    about: Please ask and answer questions here.
EOF
  log ".github/ISSUE_TEMPLATE/config.yml"
}
