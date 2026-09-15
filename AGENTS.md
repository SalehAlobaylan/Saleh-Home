# AGENTS.md — Saleh-Home workspace

Saleh-Home is the private personal engineering workspace superproject. It is
the root context for coding agents (`codex`, `claude`, `opencode`). Independent
personal repositories are mounted under `repos/` as Git submodules (or pending
submodules awaiting remotes).

## Repository map

```text
repos/salehspace
    personal website (SalehAlobaylan/salehspace, public submodule, branch main)

repos/salehalobaylan
    GitHub profile (SalehAlobaylan/SalehAlobaylan, public submodule, branch main)
    Special profile repo — must remain independent, never merge into Saleh-Home.

repos/knowledge-vault
    private Obsidian knowledge source (SalehAlobaylan/knowledge-vault, private submodule, branch main)
    Canonical source. Markdown is canonical; wikilinks are graph edges.

repos/knowledge-web
    knowledge publisher (SalehAlobaylan/knowledge-web, submodule, branch main; private until public deployment)
    Consumes only exported public Markdown. Eventually knowledge.salehspace.dev.

repos/personal-docs
    private professional documentation (SalehAlobaylan/personal-docs, private submodule, branch main)
    Resume sources, CVs, bios, career history, cover letters, portfolio copy.
```

Supporting paths: `docs/` (architecture, map, workflows, verification),
`knowledge/` (vault-starter template, guidelines, metadata, publishing),
`config/repositories.yaml` (registry), `scripts/` (setup, status, update,
export, build), `infrastructure/` (notes).

Unrelated product repositories do not belong here unless explicitly added.

## Public / private boundaries

```text
PRIVATE: Saleh-Home, knowledge-vault, personal-docs
PUBLIC:  salehspace, SalehAlobaylan/SalehAlobaylan
PUBLIC EVENTUALLY: knowledge-web, knowledge.salehspace.dev
```

Publishing rule: only the exact frontmatter `visibility: public` may enter the
pipeline (`scripts/export-public.mjs` + Quartz `ExplicitPublish`). Missing
metadata never implies public. Never publish a vault note on inference. Never
change repository visibility automatically.

## Git ownership rules

- Saleh-Home is the workspace superproject; `repos/*` are independent repos.
- Always determine which repository owns a changed file (`./scripts/status.sh`).
- Do not combine histories between repositories.
- When changing a submodule: commit inside that repository first, then update
  the Saleh-Home submodule pointer afterward when appropriate.
- Do not commit secrets. Do not force-push without explicit instruction.
- Do not rewrite personal repository history.
- `git reset --hard`, `git clean -fd`, `rm -rf` on existing repos are forbidden
  unless demonstrably safe and necessary. Preserve user work.
- The parent pins commits (snapshots); work on `main` inside children for
  active development. Do not auto-bump pointers to latest upstream.

## Knowledge rules

- Vault source: `repos/knowledge-vault`. Template only: `knowledge/vault-starter`.
- Never silently create a replacement canonical vault. Setup without
  `--create-vault` must stop with instructions when the vault is absent.
- Export boundary happens before Quartz: `repos/knowledge-vault` →
  `repos/knowledge-web/content` → Quartz build. Quartz never sees the vault.
- Build via `npm run knowledge:build` or `./scripts/build-knowledge.sh`. It
  must fail loudly on private/missing links, malformed metadata, URL
  collisions, or unsafe content.
- `personal-docs` must never contain passwords, API keys, secrets, identity
  documents, or bank records.

## Common commands

```bash
git submodule status --recursive
./scripts/status.sh            # local status, all repos
./scripts/status.sh --fetch    # include remote check
./scripts/update.sh            # safe fetch; skips dirty repos
./scripts/setup.sh             # idempotent bootstrap
npm test                       # export + setup + workspace tests
npm run knowledge:build        # export public notes + Quartz build
```

## Cross-repository task pattern

Example: "Publish my new knowledge graph and add it to SalehSpace":

```text
repos/knowledge-vault → edit/publish metadata
        → knowledge export
repos/knowledge-web   → site changes
repos/salehspace      → navigation/integration
        → commit each child repo
        → update Saleh-Home pointers
```

Keep it simple: no monorepo tooling, no orchestration, no databases, no RAG.
Git submodules are enough.
