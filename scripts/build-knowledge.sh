#!/bin/sh
# Build the public knowledge site: export public notes, then run Quartz.
# Fails loudly on unsafe links, malformed metadata, or publisher errors.
# Usage: ./scripts/build-knowledge.sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
exec node "$ROOT/scripts/build.mjs"
