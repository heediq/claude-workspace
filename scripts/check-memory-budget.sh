#!/usr/bin/env bash
set -uo pipefail

# =============================================================
# Heediq — Memory line-budget check
#
# Mechanically enforces the caps documented in
# claude-workspace/rules/08-memory.md ("Always-loaded line budget" and
# "Per-area file budget"). Run standalone, or wired in as a pre-commit
# hook by scripts/install-git-hooks.sh.
#
# Usage: bash claude-workspace/scripts/check-memory-budget.sh
# Exit code: 0 if everything is within budget, 1 if anything is over.
# =============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CW="$WORKSPACE_ROOT/claude-workspace"

fail=0

check() {
  local path="$1" cap="$2" label="$3"
  [[ -f "$path" ]] || return 0
  local lines
  lines=$(wc -l < "$path" | tr -d ' ')
  if (( lines > cap )); then
    echo "[OVER] $label: $lines lines (cap $cap) — $path"
    fail=1
  else
    echo "[ok]   $label: $lines/$cap lines"
  fi
}

echo "=== Memory line-budget check ==="
echo ""

check "$WORKSPACE_ROOT/CLAUDE.md" 150 "root CLAUDE.md"
check "$CW/CLAUDE.md" 150 "workspace CLAUDE.md"
check "$CW/memory/business/DECISIONS.md" 60 "DECISIONS.md (manifest)"
check "$CW/memory/codebase/MEMORY.md" 150 "codebase MEMORY.md (index)"
check "$CW/memory/codebase/feature_dependency_map.md" 150 "feature_dependency_map.md"

if [[ -d "$CW/memory/business/decisions" ]]; then
  for f in "$CW/memory/business/decisions"/*.md; do
    [[ -e "$f" ]] || continue
    check "$f" 150 "decisions/$(basename "$f")"
  done
fi

echo ""
if [[ "$fail" -eq 1 ]]; then
  echo "Some always-loaded or per-area files are over budget — see rules/08-memory.md."
  echo "Trim, or split an over-budget area file further, before committing."
else
  echo "All checked files are within budget."
fi

exit "$fail"
