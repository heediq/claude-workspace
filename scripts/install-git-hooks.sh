#!/usr/bin/env bash
set -euo pipefail

# =============================================================
# Heediq — Install claude-workspace git hooks
#
# Wires scripts/check-memory-budget.sh in as a pre-commit hook so
# always-loaded/per-area memory files can't silently drift over their
# line budget (rules/08-memory.md). Git hooks aren't tracked by git
# itself, so each clone runs this once (setup-workspace.sh calls it).
#
# Usage: bash claude-workspace/scripts/install-git-hooks.sh
# =============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CW_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$CW_ROOT/.git/hooks"
HOOK="$HOOKS_DIR/pre-commit"

if [[ ! -d "$CW_ROOT/.git" ]]; then
  echo "[skip] $CW_ROOT is not a git repo (no .git dir) — nothing to install"
  exit 0
fi

mkdir -p "$HOOKS_DIR"

cat > "$HOOK" << EOF
#!/usr/bin/env bash
# Installed by scripts/install-git-hooks.sh — enforces rules/08-memory.md line budgets.
bash "$SCRIPT_DIR/check-memory-budget.sh"
EOF

chmod +x "$HOOK"
echo "[ok] pre-commit hook installed at $HOOK"
