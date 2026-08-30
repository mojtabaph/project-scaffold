#!/bin/bash
# lib/hooks.sh - Git hooks + commitlint + editorconfig

generate_hooks() {
  info "Git hooks"

  mkdir -p "$PROJECT_PATH/.husky"

  # Pre-commit hook
  cat > "$PROJECT_PATH/.husky/pre-commit" << 'EOF'
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

echo "Running pre-commit checks..."

# Run linting
if [ -f "package.json" ]; then
  npm run lint
fi

# Run tests
if [ -f "Makefile" ]; then
  make test
fi
EOF
  chmod +x "$PROJECT_PATH/.husky/pre-commit"
  log ".husky/pre-commit"

  # Commit-msg hook (conventional commits)
  cat > "$PROJECT_PATH/.husky/commit-msg" << 'EOF'
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

commit_msg=$(cat "$1")

# Conventional Commits pattern
pattern="^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9-]+\))?: .{1,}"

if ! echo "$commit_msg" | grep -qE "$pattern"; then
  echo "ERROR: Invalid commit message format"
  echo ""
  echo "Expected format: <type>(<scope>): <description>"
  echo ""
  echo "Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert"
  echo ""
  echo "Examples:"
  echo "  feat(auth): add login endpoint"
  echo "  fix(api): handle null response"
  echo "  docs: update README"
  exit 1
fi
EOF
  chmod +x "$PROJECT_PATH/.husky/commit-msg"
  log ".husky/commit-msg"

  # Pre-push hook
  cat > "$PROJECT_PATH/.husky/pre-push" << 'EOF'
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

echo "Running pre-push checks..."

# Run tests before push
if [ -f "Makefile" ]; then
  make test
fi
EOF
  chmod +x "$PROJECT_PATH/.husky/pre-push"
  log ".husky/pre-push"
}

generate_commitlint() {
  info "Commitlint configuration"

  cat > "$PROJECT_PATH/commitlint.config.js" << 'EOF'
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',     // New feature
        'fix',      // Bug fix
        'docs',     // Documentation
        'style',    // Formatting
        'refactor', // Code refactoring
        'perf',     // Performance
        'test',     // Tests
        'build',    // Build system
        'ci',       // CI/CD
        'chore',    // Maintenance
        'revert',   // Revert
      ],
    ],
    'subject-case': [2, 'never', ['start-case', 'pascal-case', 'upper-case']],
    'body-max-line-length': [2, 'always', 100],
  },
};
EOF
  log "commitlint.config.js"
}

generate_editorconfig() {
  info "EditorConfig"

  cat > "$PROJECT_PATH/.editorconfig" << 'EOF'
root = true

[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.md]
trim_trailing_whitespace = false

[Makefile]
indent_style = tab

[*.{go,rs}]
indent_size = 4

[*.{yml,yaml}]
indent_size = 2
EOF
  log ".editorconfig"
}
