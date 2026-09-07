# Saleh Home

Personal workspace and control repository for Saleh’s knowledge, documentation, public identity, and infrastructure. Independent software projects remain in their own repositories.

## Start writing

The working vault is the nested `knowledge-vault/` repository. In Obsidian, choose **Open folder as vault**, select that folder, and open `Home.md`. Create a note in `inbox/`, then run **Templates: Insert template → Concept**. New template notes are private.

The private GitHub repository is currently empty. In this prepared checkout, make the first local commit and push it before using the clone instructions on another machine:

```sh
git add .
git commit -m "Establish Saleh Home knowledge workspace"
git push -u origin main
```

For a fresh machine after that first push (Node.js 22+ and npm 10.9.2+, Git):

```sh
git clone https://github.com/SalehAlobaylan/Saleh-Home.git
cd Saleh-Home
./scripts/setup.sh
npm test
npm run build
cd knowledge-web
npx quartz build --serve
```

Open `http://localhost:8080`. `setup.sh` creates missing nested repositories and never overwrites an existing vault or publisher. Once your real private vault has a remote, clone it into `knowledge-vault/` **before** running setup; otherwise setup creates starter content.

## Repository boundaries

Setup prepares each new repository in a temporary directory and moves it into place only after configuration succeeds. Interrupted initialization can be retried; failed dependency installs can also be retried. Existing repositories are preserved. An incomplete checkout from an older setup reports an actionable error: move it aside for safekeeping, rerun setup, then restore any personal edits.

- **Saleh-Home**: instructions, registry, starter files, public export tooling, reproducible publisher configuration.
- **knowledge-vault**: independent nested Git repository; full authoring source. Intended GitHub visibility: private. No remote is configured yet.
- **knowledge-web**: independent nested Quartz checkout, based on v4.5.2; consumes only selected exported Markdown. No personal GitHub origin is configured yet.

The starter under `knowledge/vault-starter` is a reusable example, not a synchronized copy of the working vault. Edit your real notes in `knowledge-vault/`.

## Read next

- [Architecture](docs/architecture.md) and [repository map](docs/repository-map.md)
- [Knowledge system](docs/knowledge-system.md), [writing guidelines](knowledge/vault-guidelines.md), and [metadata](knowledge/metadata-schema.md)
- [Git and daily workflows](docs/workflows.md)
- [Publishing and Cloudflare preparation](knowledge/publishing.md)

A local public-only Quartz build is supported. The existing Saleh-Home GitHub repository is empty and private; no local workspace files have been pushed. The separate vault and publisher remotes, Cloudflare deployment, and DNS setup are not yet performed. SalehSpace is unchanged.
