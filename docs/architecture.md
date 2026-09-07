# Architecture

Saleh Home coordinates two nested repositories while keeping their Git histories independent; the control repository does not absorb their files or use submodules.

The nested repositories are intentionally ignored by the parent `.gitignore`. Their location is inside the workspace for convenience, while each repository keeps its own commits, remotes, and lifecycle.

```text
knowledge-vault (private, Obsidian + Markdown + Git)
    → Saleh-Home/scripts/export-public.mjs (explicit visibility gate)
    → knowledge-web/content (generated public Markdown only)
    → Quartz (HTML, search index, backlinks, graph)
    → Cloudflare Pages (future)
    → knowledge.salehspace.dev (future)
```

Authoring and history belong to the vault. Presentation and static assets belong to Quartz. Workspace policy and export tooling belong here. The publisher never receives the vault path during its build; it receives only exported content.

The chosen integration is a standalone subdomain. SalehSpace can later add an ordinary Knowledge navigation link to `https://knowledge.salehspace.dev`; no shared runtime, API, authentication, or changes to SalehSpace are needed now. Its title, footer, and domain are prepared in the Quartz configuration.

Markdown links are the initial graph model. No graph database, semantic ontology, embeddings, or AI automation is needed. Other publishers can consume the same public Markdown later.
