# Architecture

Saleh-Home is a private Git superproject / personal workspace. Independent
personal repositories are mounted under `repos/` as Git submodules. Each child
keeps its own commits, branches, remotes, and deployment lifecycle; Saleh-Home
tracks which commit of each repository constitutes the current workspace snapshot.

```text
Saleh-Home (private superproject)
│
├── repos/salehspace       → SalehAlobaylan/salehspace (public website, submodule)
├── repos/salehalobaylan     → SalehAlobaylan/SalehAlobaylan (public identity, submodule)
├── repos/knowledge-vault  → private Obsidian source (independent repo, remote pending)
├── repos/knowledge-web    → knowledge publisher (independent repo, remote pending)
└── repos/personal-docs    → private professional docs (independent repo, remote pending)
```

All five workspace repositories are registered in `.gitmodules` with real
GitHub remotes. Never invent remote URLs for future additions.

Knowledge flow:

```text
repos/knowledge-vault (private, Obsidian + Markdown + Git)
    → Saleh-Home/scripts/export-public.mjs (explicit visibility gate)
    → repos/knowledge-web/content (generated public Markdown only)
    → Quartz (HTML, search index, backlinks, graph)
    → Cloudflare Pages (future)
    → knowledge.salehspace.dev (future)
```

Authoring and history belong to the vault. Presentation and static assets belong
to Quartz. Workspace policy and export tooling belong here. The publisher never
receives the vault path during its build; it receives only exported content.
The export boundary happens before Quartz processes anything.

The chosen integration is a standalone subdomain. SalehSpace can later add an
ordinary Knowledge navigation link to `https://knowledge.salehspace.dev`; no
shared runtime, API, authentication, or changes to SalehSpace are needed now.
Its title, footer, and domain are prepared in the Quartz configuration.

Markdown links are the initial graph model. No graph database, semantic
ontology, embeddings, AI automation, monorepo build system, or orchestration is
needed. Other publishers can consume the same public Markdown later.

## Submodule Git behavior

Changing a submodule involves two levels of Git state:

```text
repos/salehspace
      │
      │ commit
      ▼
salehspace repository
      │
      │ new commit SHA
      ▼
Saleh-Home sees updated submodule pointer
      │
      │ commit
      ▼
Saleh-Home repository
```

```bash
cd repos/salehspace
git add .
git commit -m "Update personal website"
git push

cd ../..
git add repos/salehspace
git commit -m "Update salehspace workspace revision"
git push
```

The parent pins a commit (snapshot). For active development, work on the
intended branch (generally `main`) inside the child. Do not rewrite pointers to
arbitrary latest commits without review, and never hide this two-level behavior.
