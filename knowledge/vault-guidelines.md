# Writing guidelines

Write one meaningful idea per note and give it a clear, unique title. Prefer shallow folders; relationships come from links such as `[[Caching]]`, not folder depth. Use `[[Caching#Example|example]]` when a section or readable label helps. Avoid duplicate basenames and names that differ only by case or punctuation; they can collide in URLs or link resolution.

Capture quickly in `inbox/`. Move developed notes into `notes/`. Maps in `maps/` are ordinary index notes organized around useful questions, not a comprehensive taxonomy. The initial Backend Engineering map is private; public navigation starts at `index.md`.

Templates are guidance: remove unused sections. Explain ideas in your own words, record sources, add examples when useful, and link only when the relationship means something. Add references and reconsider earlier explanations over time.

The exporter supports public-to-public wikilinks, headings, aliases on links, embeds of public Markdown notes, and ordinary Markdown links. It conservatively checks wikilinks even inside code examples. Local attachments, raw HTML, alias-based target resolution, and unresolved links are not supported for public export in v1. Private authoring can still use Obsidian’s full feature set.

The default local graph filters out `templates/` with `-path:templates`, so writing aids do not become knowledge nodes. Private notes remain visible locally; this filter is unrelated to the public publishing gate.
