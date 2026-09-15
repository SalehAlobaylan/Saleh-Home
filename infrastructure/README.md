# Personal infrastructure

Current infrastructure is intentionally small: `scripts/setup.sh` syncs submodules and bootstraps the workspace; `scripts/status.sh` reports child repository state; `scripts/update.sh` safely fetches; the Node scripts export public notes and invoke Quartz. Cloudflare Pages and DNS instructions live in `knowledge/publishing.md`.

Registry entries document intended boundaries, not verified permissions. No bulk repository updater, secrets management framework, CI service, monorepo build system, or machine configuration system is required. Git submodules are enough.
