---
type: concept
status: learning
visibility: public
created: 2026-09-07
updated: 2026-09-07
tags: []
---

# Cache Invalidation

Cache invalidation marks or removes a cached result when it should no longer be used. It is one of the core correctness concerns in [[Caching]].

Expiration limits how long a result can remain cached. Explicit invalidation removes a result when its source changes. The right choice depends on how much stale data the application can tolerate.
