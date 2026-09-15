# Saleh Home

Saleh Home is my private personal engineering workspace.

It acts as a single entry point for coding agents while keeping
my personal repositories independently versioned through Git submodules.

```text
ONE PLACE TO ENTER — MULTIPLE INDEPENDENT REPOSITORIES — ONE SHARED AGENT CONTEXT
```

## Layout

```text
Saleh-Home/
├── repos/salehspace       → personal website (public submodule)
├── repos/salehalobaylan     → GitHub profile (public submodule)
├── repos/knowledge-vault  → private Obsidian source (private submodule)
├── repos/knowledge-web    → public knowledge publisher (submodule, private until deployment)
└── repos/personal-docs    → private professional docs (private submodule)
```

See `AGENTS.md` for agent rules, `docs/architecture.md` for design,
`docs/repository-map.md` for remote setup, and `config/repositories.yaml`
for the registry.

## Clone

```bash
git clone --recurse-submodules git@github.com:SalehAlobaylan/Saleh-Home.git
cd Saleh-Home
./scripts/setup.sh
```

`setup.sh` syncs submodule config, initializes missing registered submodules,
verifies tools and repositories, and installs dependencies. It preserves
existing files and never overwrites user work. If `repos/knowledge-vault` is
absent it stops with instructions — the canonical vault is never silently
recreated. To explicitly start a new template vault:

```bash
./scripts/setup.sh --create-vault
```

Requirements: Git, Node.js 22+, npm 10.9.2+.

## Open with a coding agent

```bash
cd Saleh-Home
codex   # or: claude / opencode
```

The agent root context is `AGENTS.md` (`CLAUDE.md` points to it). It explains
the repo map, Git boundaries, and publishing privacy rules.

## Where is my knowledge vault?

`repos/knowledge-vault/` — open that folder in Obsidian, start at `Home.md`.
Create notes in `inbox/`, then run **Templates: Insert template → Concept**.
New template notes are private by default.

`knowledge/vault-starter/` is only a reusable template, never the real source:

```text
knowledge/vault-starter  = reusable template
repos/knowledge-vault    = canonical knowledge source
```

## How do I build public knowledge?

```bash
npm test
npm run knowledge:build
cd repos/knowledge-web
npx quartz build --serve
# open http://localhost:8080
```

Only notes with the exact frontmatter `visibility: public` are exported, and
only after link/metadata safety checks pass. Quartz never sees the private
vault — the export boundary happens first. See `knowledge/publishing.md`.

## How do Git commits work across submodules?

Each `repos/*` directory is its own repository. Commit inside the child first,
then update the Saleh-Home pointer:

```bash
cd repos/salehspace
git add . && git commit -m "Update personal website" && git push
cd ../..
git add repos/salehspace
git commit -m "Update salehspace workspace revision"
git push
```

Use `./scripts/status.sh` to see every repo's branch and working-tree state,
and `./scripts/update.sh` for safe fetches (it never touches dirty repos or detached checkouts).

## Read next

- [Architecture](docs/architecture.md) and [repository map](docs/repository-map.md)
- [Knowledge system](docs/knowledge-system.md), [writing guidelines](knowledge/vault-guidelines.md), and [metadata](knowledge/metadata-schema.md)
- [Git and daily workflows](docs/workflows.md)
- [Publishing and Cloudflare preparation](knowledge/publishing.md)
- [Verification](docs/verification.md)
