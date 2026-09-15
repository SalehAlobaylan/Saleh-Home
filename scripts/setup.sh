#!/bin/sh
# Saleh-Home workspace bootstrap.
#
# Idempotent and non-destructive:
#   - syncs submodule configuration and initializes registered submodules
#   - never overwrites existing files or discards uncommitted work
#   - never silently creates a replacement canonical vault
#
# Usage:
#   ./scripts/setup.sh [--create-vault]
#
# When repos/knowledge-vault is absent and no submodule remote is configured,
# setup stops with instructions. Pass --create-vault to explicitly bootstrap
# a new vault from knowledge/vault-starter (template only, never a restore).
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

command -v git >/dev/null 2>&1 || { printf '%s\n' "Missing required tool: git" >&2; exit 1; }
command -v node >/dev/null 2>&1 || { printf '%s\n' "Missing required tool: node (22+ required)" >&2; exit 1; }
command -v npm >/dev/null 2>&1 || { printf '%s\n' "Missing required tool: npm" >&2; exit 1; }

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

# Registered submodules (salehspace, github-profile). Safe to init/update:
# git never overwrites uncommitted work in submodules during update --init.
if [ -f "$ROOT/.gitmodules" ]; then
  git -C "$ROOT" submodule sync --recursive
  git -C "$ROOT" submodule update --init --recursive
fi

# --- Knowledge vault: source of truth, never fabricated silently. ---
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
test -d "$VAULT/.git" || { printf '%s\n' "Vault is not an independent Git repository: $VAULT" \
  "Preserve this directory elsewhere, then restore a valid vault clone or rerun with --create-vault on an empty path." >&2; exit 1; }

# --- Knowledge web: Quartz publisher (safe to bootstrap from upstream template). ---
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
  printf '%s\n' "Bootstrapped publisher at $WEB from Quartz v4.5.2. Create a personal remote later; see docs/repository-map.md."
fi
test -d "$WEB/.git" || { printf '%s\n' "Publisher is not an independent Git repository: $WEB" >&2; exit 1; }
for REQUIRED in quartz.config.ts quartz.layout.ts package.json package-lock.json; do
  test -f "$WEB/$REQUIRED" || { printf '%s\n' "Incomplete publisher: missing $REQUIRED. Preserve this directory outside repos/knowledge-web, then rerun setup." >&2; exit 1; }
done
if cmp -s "$WEB/quartz.config.ts" "$ROOT/config/quartz.config.ts"; then
  :
elif test "$(git -C "$WEB" rev-parse HEAD)" = "4923affa7722dfc751f1074348e6dad214fe0c08" && git -C "$WEB" show HEAD:quartz.config.ts > "$SETUP_STAGE/upstream-config" && cmp -s "$WEB/quartz.config.ts" "$SETUP_STAGE/upstream-config"; then
  printf '%s\n' 'Publisher still has upstream configuration. Preserve this directory outside repos/knowledge-web, then rerun setup; restore any personal edits afterward.' >&2
  exit 1
fi

# --- Personal docs: optional, pending remote is fine. ---
if [ ! -e "$DOCS" ]; then
  printf '%s\n' "Note: personal docs not found at $DOCS (pending private remote — see docs/repository-map.md). Continuing without it."
elif [ ! -d "$DOCS/.git" ]; then
  printf '%s\n' "Note: $DOCS exists but is not an independent Git repository. Leaving it untouched; convert to a private repo when ready." >&2
fi

npm --prefix "$ROOT" ci --ignore-scripts
if [ -d "$WEB/.git" ]; then
  npm --prefix "$WEB" ci
fi
printf '%s\n' "Setup complete. Open $VAULT in Obsidian. Run npm run knowledge:build from $ROOT."
