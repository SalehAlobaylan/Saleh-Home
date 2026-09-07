# Personal infrastructure

Current infrastructure is intentionally small: `scripts/setup.sh` bootstraps the nested repositories; the Node scripts export public notes and invoke Quartz. Cloudflare Pages and DNS instructions live in `knowledge/publishing.md`.

Registry entries document intended boundaries, not verified permissions. No bulk repository updater, secrets management framework, CI service, or machine configuration system is required for this phase.
