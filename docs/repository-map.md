# Repository map

`config/repositories.yaml` records roles, local paths, submodule state, and
intended visibility. Registry values document reality — they do not configure
or verify GitHub permissions and must never be used as a publishing gate.

| Repository | Role | Location / state |
| --- | --- | --- |
| SalehAlobaylan/Saleh-Home | Personal workspace superproject (private) | Current directory; submodule pointers + docs + tooling |
| SalehAlobaylan/SalehSpace | Personal website (public) | `repos/salehspace`, Git submodule, branch `main` |
| SalehAlobaylan/SalehAlobaylan | GitHub profile (public) | `repos/salehalobaylan`, Git submodule, branch `main` |
| knowledge-vault | Private Obsidian authoring source | `repos/knowledge-vault`, Git submodule, branch `main`, private remote |
| knowledge-web | Public knowledge publisher (Quartz) | `repos/knowledge-web`, Git submodule, branch `main`; personal origin + upstream `jackyzha0/quartz` |
| personal-docs | Private professional docs | `repos/personal-docs`, Git submodule, branch `main`, private remote |

These are independent repositories mounted as submodules, never merged histories.

## Remote setup reference

All five workspace repositories now have remotes. For any future addition,
do not fabricate URLs:

1. Create the GitHub repository with the intended visibility and verify it in
   the GitHub UI. Do not infer visibility from local config.
   - `knowledge-vault`: **private**
   - `personal-docs`: **private**
   - `knowledge-web`: private until public deployment is ready
2. Inside the child repo, commit work, add the remote, and push:
   ```bash
   cd repos/knowledge-vault
   git remote add origin git@github.com:SalehAlobaylan/knowledge-vault.git
   git push -u origin main
   ```
3. Register as a submodule from the Saleh-Home root:
   ```bash
   cd ../..
   git submodule add -b main git@github.com:SalehAlobaylan/knowledge-vault.git repos/knowledge-vault
   ```
   (If the directory already contains history, commit and push it first, move
   it aside, run `git submodule add` to clone, verify history is intact, then
   remove the backup — never `rm -rf` blindly or use `reset --hard`.)
4. Update `config/repositories.yaml` and run `./scripts/status.sh` + `npm test`.

Keep full vault history out of any public repository, even when all current
files appear publishable.
