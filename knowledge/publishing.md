# Public publishing

## Local boundary

Public exports omit `related` metadata so private note names cannot cross that boundary. Conflicting Quartz URLs (for example `Cache Invalidation.md` and `Cache-Invalidation.md`) stop export before replacing existing output.

`npm run build` runs the exporter, then Quartz only if export succeeds. `npm run export` performs selection alone. The CLI optionally accepts explicit vault and output directories; use a dedicated output directory whose parent exists.

The exporter parses YAML and accepts only exact `visibility: public`. It checks wikilinks and Markdown links against opted-in notes, rejects missing/private/ambiguous targets, symlinks, images, local non-Markdown assets, unsupported URL schemes, and raw HTML. It does not copy `.obsidian`, hidden folders, templates, attachments, or the vault’s Git history. It removes stale notes on successful re-export. Arbitrary output directories are protected by a generated marker file.

This is a selection gate, not a content classifier: private information pasted into an opted-in note, title, tag, code example, or external URL is still public. Review the actual export. Assets can be added later with their own explicit reviewed allowlist; no attachment is automatically published now.

Quartz is pinned to v4.5.2 (commit `4923affa7722dfc751f1074348e6dad214fe0c08`). `config/quartz.config.ts` enables ExplicitPublish as a second gate, prepares `knowledge.salehspace.dev`, disables analytics, and uses frontmatter dates. The publisher package manifests in `config/` include audited dependency updates (including sharp 0.35.4 and toml 5.0.0); setup applies those exact manifests to new checkouts. Layout retains Quartz graph, search, navigation, and backlinks. It is not a custom frontend.

## Cloudflare Pages preparation

Create a separate knowledge-web remote containing the publisher and reviewed exported `content/`, never the full vault or its history. Connect **only that repository** to Pages. No vault access token is needed in Cloudflare.

| Setting | Value |
| --- | --- |
| Production branch | main |
| Framework preset | None |
| Build command | npm ci && npx quartz build |
| Output directory | public |
| Node version | 22 or newer supported LTS |

Add `knowledge.salehspace.dev` through the Pages custom-domain interface, then follow Cloudflare’s DNS instructions for the zone. Deployment and DNS are preparatory; no site has been deployed. Later add a Knowledge link in SalehSpace as a separate website change.

Publish updates by exporting locally, building, reviewing the content diff, and committing/pushing that public snapshot to knowledge-web. The private vault remains in the nested `knowledge-vault/` repository and its private remote. Prefer this manual boundary until an actual need justifies automation.

Sources: [Quartz hosting](https://quartz.jzhao.xyz/hosting), [Cloudflare custom domains](https://developers.cloudflare.com/pages/configuration/custom-domains/), and the pinned Quartz source checked out in knowledge-web.
