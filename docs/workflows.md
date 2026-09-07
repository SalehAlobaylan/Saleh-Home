# Workflows

## Write and sync

1. In the vault terminal, run `git status` and `git pull --ff-only` before editing, once an origin and initial commit exist.
2. Write in Obsidian, use the Concept template, add meaningful links, and manually update `updated` when the understanding changes. Obsidian core templates insert dates; they do not maintain them automatically.
3. Review `git diff` and `git status`. Stage intended files, commit, then push to the private origin.
4. On another desktop, pull before editing. Resolve conflicts as Markdown; do not force-push over another device’s work.

For the initial Saleh-Home backup, the existing GitHub repository is already private and empty. Review the staged workspace files, create the first commit, then run `git push -u origin main`. For the vault, first create a private empty knowledge-vault repository on GitHub, verify its visibility, add its URL as origin, review and commit the vault files, then run `git push -u origin main`. No credentials or additional remote repositories are created by setup.

Git is an explicit developer sync workflow, not real-time Obsidian Sync. Mobile synchronization is deferred. Git history retains deleted content, so credentials and sensitive identity or financial documents never belong in these repositories.

## Publish locally

1. Review the complete note body, title, tags, and links. Set `visibility: public` only when ready.
2. From Saleh-Home, run `npm test` and `npm run build`.
3. In knowledge-web, run `npx quartz build --serve`; inspect search, graph, backlinks, and the pages at `http://localhost:8080`.
4. Review the generated `content/` diff before any future public commit or deployment.

A failed export stops the build; the previous generated files may still exist and must not be treated as a newly approved export. After changing visibility back to private, successfully rebuild and redeploy to remove it from the live site. Previously public copies and Git history cannot be recalled.

## Separate histories

Each nested directory has its own Git status, commits, and remote. Committing Saleh-Home never backs up the vault. Do not run Quartz’s sync command against the vault. Do not merge the vault’s Git history into knowledge-web.
