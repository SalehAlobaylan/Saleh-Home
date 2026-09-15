#!/bin/sh
# Conservative workspace updater.
#   - syncs submodule URLs (config only, never touches worktrees)
#   - initializes MISSING submodules only (never checks out over existing work)
#   - fetches each repo; pulls only fast-forward on clean, on-branch checkouts
#   - skips dirty repositories and detached HEADs with a message
#   - NEVER resets, checks out over uncommitted changes, force-pushes, or rewrites history
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

# Config-only; safe even with dirty worktrees.
git -C "$ROOT" submodule sync --recursive

# Initialize only submodules that were never cloned ('-' prefix in status).
# Existing checkouts are left untouched; the per-repo logic below decides.
if [ -f "$ROOT/.gitmodules" ]; then
  MISSING=$(git -C "$ROOT" submodule status --recursive | awk '$1 ~ /^-/ { print $2 }')
  if [ -n "$MISSING" ]; then
    # Intentional word splitting: one path per line from awk.
    # shellcheck disable=SC2086
    if ! git -C "$ROOT" submodule update --init --recursive -- $MISSING; then
      printf '%s\n' "Submodule initialization failed (check network and private-repo access)." \
        "Fix and rerun; existing checkouts were not touched." >&2
      exit 1
    fi
  fi
fi

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
  if ! git -C "$DIR" remote get-url origin >/dev/null 2>&1 && ! git -C "$DIR" remote get-url upstream >/dev/null 2>&1; then
    printf '%s\n' "$LABEL: no remote configured — left untouched."
    return
  fi
  # A failed fetch must not abort the remaining repos (set -e).
  if ! git -C "$DIR" fetch --prune; then
    printf '%s\n' "$LABEL: fetch failed (offline or unreachable remote) — left untouched."
    return
  fi
  UPSTREAM=$(git -C "$DIR" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
  if [ -z "$UPSTREAM" ]; then
    printf '%s\n' "$LABEL: fetched; no upstream tracking branch — left untouched."
    return
  fi
  AHEAD_BEHIND=$(git -C "$DIR" rev-list --left-right --count HEAD..."$UPSTREAM" 2>/dev/null || true)
  if [ -z "$AHEAD_BEHIND" ]; then
    AHEAD_BEHIND="unknown"
  fi
  # Fast-forward only; refuse anything destructive.
  if git -C "$DIR" pull --ff-only; then
    printf '%s\n' "$LABEL: updated ($BRANCH, previously $AHEAD_BEHIND vs $UPSTREAM)"
  else
    printf '%s\n' "$LABEL: pull did not complete (not fast-forward, diverged, or network issue) — left untouched."
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
