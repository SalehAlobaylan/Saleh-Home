#!/bin/sh
# Conservative workspace updater.
#   - syncs submodule URLs
#   - initializes missing registered submodules
#   - fetches (no merges) and reports what is behind
#   - NEVER resets, checkouts over, or discards uncommitted changes
#   - NEVER force-pushes or rewrites history
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

git -C "$ROOT" submodule sync --recursive
git -C "$ROOT" submodule update --init --recursive

report() {
  DIR="$1"
  LABEL="$2"
  if [ ! -d "$DIR/.git" ] && [ ! -f "$DIR/.git" ]; then
    printf '%s\n' "$LABEL: skipped (not an independent Git repository)"
    return
  fi
  if [ -n "$(git -C "$DIR" status --porcelain)" ]; then
    printf '%s\n' "$LABEL: skipped pull — uncommitted changes present. Commit or stash first."
    return
  fi
  BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null || true)
  if [ -z "$BRANCH" ]; then
    printf '%s\n' "$LABEL: skipped pull — detached HEAD. Switch to a branch first."
    return
  fi
  if git -C "$DIR" remote get-url origin >/dev/null 2>&1 || git -C "$DIR" remote get-url upstream >/dev/null 2>&1; then
    git -C "$DIR" fetch --prune
    UPSTREAM=$(git -C "$DIR" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
    if [ -n "$UPSTREAM" ]; then
      AHEAD_BEHIND=$(git -C "$DIR" rev-list --left-right --count HEAD..."$UPSTREAM" 2>/dev/null || echo "?	?")
      # Fast-forward only; refuse anything destructive.
      if git -C "$DIR" pull --ff-only; then
        printf '%s\n' "$LABEL: updated ($BRANCH, $AHEAD_BEHIND vs $UPSTREAM before pull)"
      else
        printf '%s\n' "$LABEL: pull needs review (non-fast-forward or no upstream). Left untouched."
      fi
    else
      printf '%s\n' "$LABEL: fetched; no upstream tracking branch — left untouched."
    fi
  else
    printf '%s\n' "$LABEL: no remote configured — left untouched."
  fi
}

report "$ROOT" "saleh-home"
report "$ROOT/repos/salehspace" "salehspace"
report "$ROOT/repos/salehalobaylan" "salehalobaylan"
report "$ROOT/repos/knowledge-vault" "knowledge-vault"
report "$ROOT/repos/knowledge-web" "knowledge-web"
report "$ROOT/repos/personal-docs" "personal-docs"

printf '%s\n' ""
printf '%s\n' "Done. Review 'git submodule status --recursive' and commit submodule pointers intentionally."
