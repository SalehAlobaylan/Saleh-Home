#!/bin/sh
# Saleh-Home workspace status.
# Local-only by default (no network fetch). Pass --fetch to update remotes first.
# Never modifies working trees.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FETCH=0
for arg in "$@"; do
  case "$arg" in
    --fetch) FETCH=1 ;;
    -h|--help) printf '%s\n' "Usage: status.sh [--fetch]"; exit 0 ;;
    *) printf '%s\n' "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

fetch_all() {
  git -C "$ROOT" fetch --recurse-submodules=no 2>/dev/null || true
  for SUB in salehspace salehalobaylan knowledge-vault knowledge-web personal-docs; do
    DIR="$ROOT/repos/$SUB"
    if [ -d "$DIR/.git" ] || [ -f "$DIR/.git" ]; then
      git -C "$DIR" fetch --prune 2>/dev/null || \
        printf '%s\n' "warning: fetch failed for $SUB (offline or unreachable remote); showing last known state." >&2
    fi
  done
}

if [ "$FETCH" = 1 ]; then
  fetch_all
fi

printf '%s\n' "Saleh Home"
printf '%s\n' ""

report_repo() {
  NAME="$1"
  DIR="$2"
  if [ ! -e "$DIR" ]; then
    printf '%s\n' "$NAME"
    printf '%s\n' "  not configured"
    printf '%s\n' ""
    return
  fi
  if [ ! -d "$DIR/.git" ] && [ ! -f "$DIR/.git" ]; then
    printf '%s\n' "$NAME"
    printf '%s\n' "  present but not an independent Git repository: $DIR"
    printf '%s\n' ""
    return
  fi
  BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null || true)
  if [ -z "$BRANCH" ]; then
    BRANCH="(detached @ $(git -C "$DIR" rev-parse --short HEAD 2>/dev/null || printf 'unknown'))"
  fi
  if [ -z "$(git -C "$DIR" status --porcelain 2>/dev/null)" ]; then
    STATUS="clean"
  else
    MODIFIED=$(git -C "$DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    STATUS="$MODIFIED modified file(s)"
  fi
  printf '%s\n' "$NAME"
  printf '%s\n' "  path: ${DIR#$ROOT/}"
  printf '%s\n' "  branch: $BRANCH"
  printf '%s\n' "  status: $STATUS"
  UPSTREAM=$(git -C "$DIR" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
  if [ -n "$UPSTREAM" ]; then
    AHEAD_BEHIND=$(git -C "$DIR" rev-list --left-right --count HEAD..."$UPSTREAM" 2>/dev/null || true)
    if [ -n "$AHEAD_BEHIND" ]; then
      AHEAD=$(printf '%s' "$AHEAD_BEHIND" | cut -f1)
      BEHIND=$(printf '%s' "$AHEAD_BEHIND" | cut -f2)
      if [ "$AHEAD" = "0" ] && [ "$BEHIND" = "0" ]; then
        printf '%s\n' "  origin: synced ($UPSTREAM)"
      else
        printf '%s\n' "  origin: ahead $AHEAD, behind $BEHIND ($UPSTREAM)"
      fi
    fi
  else
    ORIGIN_URL=$(git -C "$DIR" remote get-url origin 2>/dev/null || true)
    if [ -z "$ORIGIN_URL" ]; then
      # knowledge-web uses 'upstream' for Quartz; report it separately.
      UPSTREAM_URL=$(git -C "$DIR" remote get-url upstream 2>/dev/null || true)
      if [ -n "$UPSTREAM_URL" ]; then
        printf '%s\n' "  origin: no personal origin (upstream: $UPSTREAM_URL)"
      else
        printf '%s\n' "  origin: no remote configured"
      fi
    else
      printf '%s\n' "  origin: $ORIGIN_URL (no upstream tracking)"
    fi
  fi
  printf '%s\n' ""
}

report_repo "saleh-home" "$ROOT"
report_repo "salehspace" "$ROOT/repos/salehspace"
report_repo "salehalobaylan" "$ROOT/repos/salehalobaylan"
report_repo "knowledge-vault" "$ROOT/repos/knowledge-vault"
report_repo "knowledge-web" "$ROOT/repos/knowledge-web"
report_repo "personal-docs" "$ROOT/repos/personal-docs"
