# Metadata schema v1

```yaml
---
type: concept
status: seed
visibility: private
created: 2026-09-07
updated: 2026-09-07
tags: []
related: []
---
```

| Property | Convention |
| --- | --- |
| type | Start with concept, technology, pattern, reference, index; extend only as useful |
| status | seed, learning, understood, applied, mature; self-assessment, not a publishing gate |
| visibility | private or public; only the exact string public opts in |
| created / updated | YYYY-MM-DD; update manually as appropriate |
| tags | Small list of useful cross-cutting labels |
| related | Optional list of related note names; body wikilinks remain the graph source of truth |
| title | Optional public display title |

Missing visibility, unknown values, booleans, and missing frontmatter do not publish. Malformed or duplicate YAML keys stop export. Other fields are permitted in the private source, but are not exported. Only title, tags, created, and updated are retained alongside generated public visibility and `publish: true` for Quartz. Treat those retained fields as public content.

Use body links for relationships in v1; `related` is optional private authoring metadata and is always omitted from public exports. Templates default to seed/private. Status and type remain flexible authoring conventions, not required bureaucracy.
