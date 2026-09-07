#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VAULT="$ROOT/knowledge-vault"
WEB="$ROOT/knowledge-web"
SETUP_STAGE=$(mktemp -d "$ROOT/.setup.XXXXXX")
trap 'rm -rf "$SETUP_STAGE"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
if [ ! -e "$VAULT" ]; then
  cp -R "$ROOT/knowledge/vault-starter" "$SETUP_STAGE/vault"
  git -C "$SETUP_STAGE/vault" init -b main
  mv "$SETUP_STAGE/vault" "$VAULT"
fi
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
fi
# Reject incomplete old installations explicitly; never overwrite existing edits.
test -d "$VAULT/.git" || { printf '%s\n' "Vault is not initialized as a separate Git repository: $VAULT" >&2; exit 1; }
test -d "$WEB/.git" || { printf '%s\n' "Publisher is not initialized as a separate Git repository: $WEB" >&2; exit 1; }
for REQUIRED in quartz.config.ts quartz.layout.ts package.json package-lock.json; do
  test -f "$WEB/$REQUIRED" || { printf '%s\n' "Incomplete publisher: missing $REQUIRED. Preserve this directory outside knowledge-web, then rerun setup." >&2; exit 1; }
done
if cmp -s "$WEB/quartz.config.ts" "$ROOT/config/quartz.config.ts"; then
  :
elif test "$(git -C "$WEB" rev-parse HEAD)" = "4923affa7722dfc751f1074348e6dad214fe0c08" && git -C "$WEB" show HEAD:quartz.config.ts > "$SETUP_STAGE/upstream-config" && cmp -s "$WEB/quartz.config.ts" "$SETUP_STAGE/upstream-config"; then
  printf '%s\n' 'Publisher still has upstream configuration. Preserve this directory outside knowledge-web, then rerun setup; restore any personal edits afterward.' >&2
  exit 1
fi
npm --prefix "$ROOT" ci --ignore-scripts
npm --prefix "$WEB" ci
printf '%s\n' "Open $VAULT in Obsidian. Run npm run build from $ROOT."
