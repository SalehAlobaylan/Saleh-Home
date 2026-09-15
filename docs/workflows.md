# Workflows

## Git boundaries

Saleh-Home is the workspace superproject. `repos/*` entries are independent
Git repositories. Always determine which repository owns a changed file:

```bash
./scripts/status.sh
git -C repos/salehspace status
git -C repos/knowledge-vault status
```

- Do not combine histories between repositories.
- When changing a submodule, commit inside that repository first, then update
  the Saleh-Home submodule pointer afterward when appropriate.
- Do not force-push without explicit instruction. Do not rewrite personal
  repository history.
- The parent pins a commit; for active work use the intended branch inside the
  child (generally `main`). Detached HEAD in a submodule means you are on a
  pinned commit, not a branch — switch back before editing.

Example:

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

Committing Saleh-Home never backs up vault file contents — it only records
submodule pointers. Do not run Quartz's sync command against the vault. Do not
merge the vault's Git history into repos/knowledge-web.

## Write and sync (vault)

1. In the vault (`repos/knowledge-vault`), run `git status` and
   `git pull --ff-only` before editing, once an origin exists.
2. Write in Obsidian, use the Concept template, add meaningful links, and
   manually update `updated` when understanding changes.
3. Review `git diff` and `git status`. Stage intended files, commit, then push
   to the private origin.
4. On another desktop, pull before editing. Resolve conflicts as Markdown; do
   not force-push over another device's work.

For the vault remote: create a **private** empty repository on GitHub, verify
its visibility, add its URL as origin, review and commit the vault files, then
run `git push -u origin main`. No credentials or additional remotes are created
by setup.

Git is an explicit developer sync workflow, not real-time Obsidian Sync. Git
history retains deleted content, so credentials and sensitive identity or
financial documents never belong in these repositories.

## Publish locally

1. Review the complete note body, title, tags, and links. Set
   `visibility: public` only when ready.
2. From Saleh-Home, run `npm test` and `npm run knowledge:build`.
3. In `repos/knowledge-web`, run `npx quartz build --serve`; inspect search,
   graph, backlinks, and the pages at `http://localhost:8080`.
4. Review the generated `content/` diff before any future public commit or
   deployment.

A failed export stops the build; the previous generated files may still exist
and must not be treated as a newly approved export. After changing visibility
back to private, successfully rebuild and redeploy to remove it from the live
site. Previously public copies and Git history cannot be recalled.

## Cross-repository example

"Publish my new knowledge graph and add it to SalehSpace":

```text
repos/knowledge-vault  → edit/publish note metadata
        │
        │ knowledge export
        ▼
repos/knowledge-web    → graph/site changes
        │
        ▼
repos/salehspace       → navigation/integration
        │
        ▼
commit each changed child repository
        │
        ▼
update Saleh-Home submodule pointers
```

## Workspace helpers

- `./scripts/status.sh` — local status for every repo (add `--fetch` for remote check)
- `./scripts/update.sh` — safe fetch/pull; refuses to touch dirty repos
- `./scripts/setup.sh` — idempotent bootstrap; never overwrites work
- `npm run knowledge:build` — export + Quartz build
