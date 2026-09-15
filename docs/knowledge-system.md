# Knowledge system

The main project goal is the private Obsidian vault at `repos/knowledge-vault/`.
Its shallow folders are `inbox/`, `notes/`, `maps/`, `templates/`, and
`attachments/`. `Home.md` is private navigation; `index.md` is the explicit
public landing page.

`knowledge/vault-starter/` is a reusable bootstrap template and example vault.
It is never the real knowledge source once `repos/knowledge-vault` exists:

```text
knowledge/vault-starter  = reusable template
repos/knowledge-vault    = canonical knowledge source
```

The starter includes two linked public example concepts and a private map and
scratchpad. They demonstrate links and export behavior; they do not assert
Saleh's expertise. Replace or expand them as you learn.

Core Obsidian features provide templates, search, properties, backlinks,
outgoing links, graph, and tags. No community plugins are required. Portable
Markdown is canonical. Configuration versions only useful settings; per-device
workspace state, cache, plugins, and trash are ignored.

## Metadata v1

```yaml
---
type: concept
status: seed
visibility: private
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: []
related: []
---
```

`visibility: private` is the safe default. Only the exact explicit value
`visibility: public` may enter the publishing pipeline. Missing metadata must
never imply public. See `knowledge/metadata-schema.md`.

## Publishing boundary

Public/private filtering is applied before Quartz parses files. Quartz graph
and backlinks therefore use only exported notes. Local Obsidian graph can
include the full private vault. This is intentional:

```text
FULL PRIVATE VAULT
        │
        │ filter first
        ▼
PUBLIC MARKDOWN EXPORT
        │
        ▼
Quartz (repos/knowledge-web)
        │
        ▼
knowledge.salehspace.dev
```

Quartz must not receive the full private vault and then decide what to hide.
