# Maintaining this repository

[← README](../README.md) · [Documentation index](README.md)

```text
README.md  docs/                    # the overview and one page per topic (docs/workflows/ has one page per ecosystem)
VERSION                              # the version of this repository (plain text, e.g. 1.0.0)
actions/                             # reusable composite actions, one kebab-case folder each
├── check-version/            ├── read-npm-package/
├── create-release/           ├── read-python-dist/
├── github-release/           ├── registry-version-exists/
├── install-node-deps/        ├── require-secrets/
├── packagist-notify/         ├── set-published/
├── setup-node-project/       └── verify-tag/
scripts/
├── update-version.sh                # set / check the version everywhere
├── validate-actions.py              # action rules + every call checked against inputs/outputs + shellcheck
├── check-actions-latest.sh          # reports third-party actions that are not on their latest release
├── test-semver.sh                   # tests the semver logic shared by check-version and create-release
└── test-update-version.sh           # tests update-version.sh
.github/
├── dependabot.yml                   # daily bumps of every third-party action reference
└── workflows/
    ├── _publish.yml                 # everything for a push to main in ONE run: lint, check-version, verify-sync, create-release
    ├── check-version.yml            # internal: runs ./actions/check-version
    ├── create-release.yml           # internal: runs ./actions/create-release
    ├── lint.yml                     # actionlint, yamllint, markdownlint, action validation, version sync, tests
    └── publish-*.yml                # the 18 publishing workflows
.yamllint.yml  .markdownlint.jsonc  .editorconfig
```

- **Add an ecosystem:** copy the closest `publish-*.yml`, keep the shared inputs (`working_directory`, `verify_tag`, `tag_prefix`, `skip_if_published`, `dry_run`) and outputs (`version`, `published`), build it from the actions above, declare every secret under `workflow_call.secrets`, add a page `docs/workflows/<name>.md` plus a row in the README table and in `docs/workflows/README.md`, and raise `VERSION` (minor).
- **Add an action:** create `actions/<kebab-case-name>/action.yml` following the [rules](actions.md), add a section to `docs/actions.md`, and run `python3 scripts/validate-actions.py`.

<a id="linting"></a>

## Linting and warnings

`lint.yml` runs on every pull request, and on every push to `main` as the first job of `_publish.yml` (so a push never starts a second, separate lint run):

| Check | Tool | Config |
| --- | --- | --- |
| Workflow syntax, expressions, permissions | `actionlint` (with `shellcheck` on every script) | – |
| Scripts in workflows and actions at style level | `shellcheck` via `scripts/validate-actions.py` | – |
| Action rules and every call's inputs/outputs | `scripts/validate-actions.py` | – |
| YAML style | `yamllint` | [`.yamllint.yml`](../.yamllint.yml) |
| Markdown style (`README.md` and `docs/`) | `markdownlint` | [`.markdownlint.jsonc`](../.markdownlint.jsonc) |
| Versions in sync | `scripts/update-version.sh --check` | – |
| Semver logic, version script | `scripts/test-semver.sh`, `scripts/test-update-version.sh` | – |

The linter configs only switch off rules that do not fit this repository: line length (scripts and `${{ }}` expressions are long), the `---` document marker, `on:` being read as a boolean, and the final-newline rules (a missing newline at the end of a file is cosmetic and must never block a release; `.editorconfig` still asks editors to add it). Everything else is fixed in the files rather than silenced.

> If you ever make this repository private, enable *Settings → Actions → General → Access* so other repositories may use the workflows and actions.
