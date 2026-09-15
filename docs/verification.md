# Workspace verification

How to verify the Saleh-Home workspace. Prefer these checks over any
single-session history.

## Submodules and remotes

```bash
git submodule status --recursive
cat .gitmodules
git remote -v
```

Expected:

- `repos/salehspace` → `SalehAlobaylan/salehspace`, branch `main`
- `repos/github-profile` → `SalehAlobaylan/SalehAlobaylan`, branch `main`
- `repos/knowledge-vault`, `repos/knowledge-web`, `repos/personal-docs` are
  registered submodules with private/personal remotes (see `docs/repository-map.md`).
  Never fabricate URLs for future additions.
- No tokens in `.gitmodules` or `config/repositories.yaml`.

## Workspace status

```bash
./scripts/status.sh
./scripts/status.sh --fetch
```

Expected: each repo listed with branch and clean/modified state; pending
remotes reported as "no remote configured" or "no personal origin" without
failure. Local status works without network.

## Tests

```bash
npm test
```

Expected: all suites pass — public-export gate (exact `visibility: public`
opt-in, private/missing link rejection, HTML/asset/symlink rejection, URL
collision handling, stale removal, output marker protection), setup safety
(missing vault stops with instructions; interrupted publisher setup is
retryable and preserves the vault), and workspace registry/path checks.

## Knowledge build

```bash
npm run knowledge:build
# or
./scripts/build-knowledge.sh
```

Expected:

- Exports only `visibility: public` notes from `repos/knowledge-vault` to
  `repos/knowledge-web/content`.
- Fails loudly on private/missing links, malformed metadata, URL collisions,
  or unsafe content — previous output is preserved, never treated as approved.
- On success, Quartz builds. Serve locally for visual check:

```bash
cd repos/knowledge-web
npx quartz build --serve
# open http://localhost:8080 — check navigation, backlinks, three-node graph
```

Verify generated `content/` contains only intended public notes and no private
sentinels or private note names:

```bash
grep -ri "scratchpad" repos/knowledge-web/content || echo "no private sentinel"
```

## Fresh-machine flow

```bash
git clone --recurse-submodules git@github.com:SalehAlobaylan/Saleh-Home.git
cd Saleh-Home
./scripts/setup.sh
npm test
npm run knowledge:build
```

`setup.sh` is idempotent: re-running preserves existing files, refuses to
overwrite user work, syncs/initializes registered submodules, bootstraps the
publisher from pinned Quartz when absent, and stops with instructions when the
vault is absent (use `--create-vault` only for an explicit new template vault).

## History preservation

```bash
git -C repos/knowledge-vault log --oneline | head
git -C repos/knowledge-web log --oneline | head
```

Vault and publisher histories are independent of Saleh-Home and of each other.
Saleh-Home commits record submodule pointers, never vault file contents.
