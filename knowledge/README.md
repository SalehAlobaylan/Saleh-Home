# Knowledge

The canonical vault is `../repos/knowledge-vault`. `vault-starter/` is a reusable
bootstrap template and example vault — it is never the real knowledge source once
the real vault exists. It is copied only by the explicit `./scripts/setup.sh --create-vault`
operation. Subsequent note edits do not flow back here.

Read [guidelines](vault-guidelines.md), [metadata](metadata-schema.md), and [publishing](publishing.md). The public examples are intentionally opted in so the first local build has linked pages. Every writing template defaults to private.
