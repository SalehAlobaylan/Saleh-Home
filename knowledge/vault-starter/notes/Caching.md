---
type: concept
status: learning
visibility: public
created: 2026-09-07
updated: 2026-09-07
tags: []
---

# Caching

Caching stores a result so a later request can reuse it rather than repeat the original work.

It can reduce latency and repeated computation, but introduces questions about freshness and storage limits. [[Cache Invalidation]] determines when a stored result should no longer be reused.

## Example

A service can cache an expensive calculation by its input. If the inputs fully determine the output, the key must capture every input that affects the result.
