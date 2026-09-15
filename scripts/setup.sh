#!/bin/sh
# Saleh-Home workspace bootstrap.
#
# Idempotent and non-destructive:
#   - syncs submodule configuration and initializes MISSING submodules only
#   - attaches submodules to their configured branch when the pinned commit
#     is the branch tip (so normal work does not start detached)
#   - never overwrites existing files or discards uncommitted work
#   - never silently creates a replacement canonical vault
#
# Usage:
#   ./scripts/setup.sh [--create-vault]
#
# When repos/knowledge-vault is absent, setup stops with instructions unless
# --create-vault explicitly bootstraps a new vault from the starter template
# (template only, never a restore of existing work).
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VAULT="$ROOT/repos/knowledge-vault"
WEB="$ROOT/repos/knowledge-web"
DOCS="$ROOT/repos/personal-docs"
CREATE_VAULT=0

for arg in "$@"; do
  case "$arg" in
    --create-vault) CREATE_VAULT=1 ;;
    -h|--help)
      printf '%s\n' "Usage: setup.sh [--create-vault]" \
        "  --create-vault  Explicitly create a new vault from knowledge/vault-starter when absent." \
        "                  Without this flag, a missing vault stops with instructions."
      exit 0
      ;;
    *) printf '%s\n' "Unknown argument: $arg (try --help)" >&2; exit 1 ;;
  esac
done

SETUP_STAGE=$(mktemp -d "$ROOT/.setup.XXXXXX")
trap 'rm -rf "$SETUP_STAGE"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

need() {
  command -v "$1" >/dev/null 2>&1 || { printf '%s\n' "Missing required tool: $1" >&2; exit 1; }
}
need git
need node
need npm

# Submodules keep their gitdir in .git/modules with a .git *file*
# (gitfile) in the worktree; plain clones have a .git directory.
# Accept both so checks work before and after submodule registration.
is_git_repo() {
  [ -d "$1/.git" ] || [ -f "$1/.git" ]
}

# Legacy locations from before the repos/ migration. Never auto-merge;
# report so the user can move history safely.
for LEGACY in "$ROOT/knowledge-vault" "$ROOT/knowledge-web"; do
  if [ -e "$LEGACY" ]; then
    printf '%s\n' "Legacy path still exists: $LEGACY" \
      "The workspace now uses repos/knowledge-vault and repos/knowledge-web." \
      "Move history safely (preserving .git) or remove the legacy copy, then rerun setup." >&2
    exit 1
  fi
done

# Config-only sync, then initialize only submodules that were never cloned.
# Existing checkouts are never checked out over.
sync_submodules() {
  [ -f "$ROOT/.gitmodules" ] || return 0
  git -C "$ROOT" submodule sync --recursive
  MISSING=$(git -C "$ROOT" submodule status --recursive | awk '$1 ~ /^-/ { print $2 }')
  if [ -n "$MISSING" ]; then
    # Intentional word splitting: one submodule path per line from awk.
    # shellcheck disable=SC2086
    git -C "$ROOT" submodule update --init --recursive -- $MISSING
  fi
}

# Attach a freshly pinned submodule to its branch when the pinned commit is
# exactly the branch tip: this changes no files, it only avoids a confusing
# detached HEAD. Dirty checkouts, missing branches, and older snapshots are
# left untouched.
attach_branch() {
  DIR="$1"
  BRANCH="$2"
  if [ ! -d "$DIR/.git" ] && [ ! -f "$DIR/.git" ]; then
    return 0
  fi
  if [ -n "$(git -C "$DIR" status --porcelain)" ]; then
    return 0
  fi
  if [ -n "$(git -C "$DIR" branch --show-current 2>/dev/null || true)" ]; then
    return 0
  fi
  TIP=$(git -C "$DIR" rev-parse --verify --quiet "refs/heads/$BRANCH" 2>/dev/null || true)
  HEAD_SHA=$(git -C "$DIR" rev-parse HEAD 2>/dev/null || true)
  if [ -n "$TIP" ] && [ -n "$HEAD_SHA" ] && [ "$HEAD_SHA" = "$TIP" ]; then
    git -C "$DIR" checkout --quiet "$BRANCH"
  fi
}

attach_submodule_branches() {
  [ -f "$ROOT/.gitmodules" ] || return 0
  for SUB in salehspace salehalobaylan knowledge-vault knowledge-web personal-docs; do
    BRANCH=$(git -C "$ROOT" config -f .gitmodules --get "submodule.repos/$SUB.branch" 2>/dev/null || true)
    [ -n "$BRANCH" ] || BRANCH=main
    attach_branch "$ROOT/repos/$SUB" "$BRANCH"
  done
}

# --- Knowledge vault: source of truth, never fabricated silently. ---
ensure_vault() {
  if [ ! -e "$VAULT" ]; then
    if [ "$CREATE_VAULT" = 1 ]; then
      cp -R "$ROOT/knowledge/vault-starter" "$SETUP_STAGE/vault"
      git -C "$SETUP_STAGE/vault" init -b main
      mv "$SETUP_STAGE/vault" "$VAULT"
      printf '%s\n' "Created new vault at $VAULT from knowledge/vault-starter template."
      printf '%s\n' "This is a fresh template, NOT a restore. Create a PRIVATE GitHub repository, verify visibility, then add it as origin."
    else
      printf '%s\n' "Knowledge vault not found: $VAULT" \
        "" \
        "The vault is the canonical private source and is never auto-created." \
        "Either:" \
        "  1. Clone your private vault repo to repos/knowledge-vault, then rerun setup; or" \
        "  2. If no vault remote exists yet, create a PRIVATE GitHub repository first," \
        "     add it as origin in repos/knowledge-vault, then rerun setup; or" \
        "  3. To explicitly start a NEW vault from the starter template, run:" \
        "       ./scripts/setup.sh --create-vault" \
        "" \
        "See docs/repository-map.md for remote setup." >&2
      exit 1
    fi
  fi
  test -d "$VAULT/.git" || test -f "$VAULT/.git" || { printf '%s\n' "Vault is not an independent Git repository: $VAULT" \
    "Preserve this directory elsewhere, then restore a valid vault clone or rerun with --create-vault on an empty path." >&2; exit 1; }
}

# --- Knowledge web: Quartz publisher (safe to bootstrap from upstream template). ---
ensure_web() {
  if [ ! -e "$WEB" ]; then
    PUBLISHER="$SETUP_STAGE/web"
    git clone --depth 1 --branch v4.5.2 https://github.com/jackyzha0/quartz.git "$PUBLISHER"
    test "$(git -C "$PUBLISHER" rev-parse HEAD)" = "4923affa7722dfc751f1074348e6dad214fe0c08"
    git -C "$PUBLISHER" switch -c main
    git -C "$PUBLISHER" remote rename origin upstream
    # Only remove the pinned upstream's sample content, never an existing user's tree.
    rm -rf "$PUBLISHER/content"
    cp "$ROOT/config/quartz.config.ts" "$PUBLISHER/quartz.config.ts"
    cp "$ROOT/config/quartz.layout.ts" "$PUBLISHER/quartz.layout.ts"
    cp "$ROOT/config/quartz.package.json" "$PUBLISHER/package.json"
    cp "$ROOT/config/quartz.package-lock.json" "$PUBLISHER/package-lock.json"
    mv "$PUBLISHER" "$WEB"
    printf '%s\n' "Bootstrapped publisher at $WEB from Quartz v4.5.2. Add a personal remote when ready; see docs/repository-map.md."
  fi
  is_git_repo "$WEB" || { printf '%s\n' "Publisher is not an independent Git repository: $WEB" >&2; exit 1; }
  for REQUIRED in quartz.config.ts quartz.layout.ts package.json package-lock.json; do
    test -f "$WEB/$REQUIRED" || { printf '%s\n' "Incomplete publisher: missing $REQUIRED. Preserve this directory outside repos/knowledge-web, then rerun setup." >&2; exit 1; }
  done
  if cmp -s "$WEB/quartz.config.ts" "$ROOT/config/quartz.config.ts"; then
    :
  elif test "$(git -C "$WEB" rev-parse HEAD)" = "4923affa7722dfc751f1074348e6dad214fe0c08" && git -C "$WEB" show HEAD:quartz.config.ts > "$SETUP_STAGE/upstream-config" && cmp -s "$WEB/quartz.config.ts" "$SETUP_STAGE/upstream-config"; then
    printf '%s\n' 'Publisher still has upstream configuration. Preserve this directory outside repos/knowledge-web, then rerun setup; restore any personal edits afterward.' >&2
    exit 1
  fi
}

# --- Personal docs: optional; a missing checkout is fine. ---
ensure_docs() {
  if [ ! -e "$DOCS" ]; then
    printf '%s\n' "Note: personal docs not found at $DOCS. Clone the private repo (or leave pending) and rerun setup."
  elif ! is_git_repo "$DOCS"; then
    printf '%s\n' "Note: $DOCS exists but is not an independent Git repository. Leaving it untouched; convert to a private repo when ready." >&2
  fi
}

install_deps() {
  npm --prefix "$ROOT" ci --ignore-scripts
  if is_git_repo "$WEB"; then
    npm --prefix "$WEB" ci
  fi
}

sync_submodules
attach_submodule_branches
ensure_vault
ensure_web
ensure_docs
install_deps
printf '%s\n' "Setup complete. Open $VAULT in Obsidian. Run npm run knowledge:build from $ROOT."
