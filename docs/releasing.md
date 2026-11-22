# Releasing and versioning

[← README](../README.md) · [Documentation index](README.md)

How this repository is versioned and released, how every version reference is kept in sync, and how third-party action versions are kept current.

<a id="releasing-this-repository"></a>

## Releasing this repository

This repository versions itself with the plain-text **`VERSION`** file and releases through [`_publish.yml`](../.github/workflows/_publish.yml) (the underscore marks it as internal – other repositories should not call it).

```text
push to main ─┬─► lint ───────────────────────────────────────────┐
              └─► check-version ─┬─ bumped ─► verify-sync ─────────┴─► create-release  (tag vX.Y.Z · GitHub Release · move vX alias)
                                 └─ not bumped ─► stop                (no tag, no release; the run summary says why)
```

One push produces **one** workflow run (`_publish`): lint, the version check and the release are jobs inside it. Pull requests run `Lint` on their own.

To release:

```bash
scripts/update-version.sh --v=1.1.0        # VERSION + every action reference + README aliases
git add -A && git commit -m "chore: release 1.1.0"
git push                                   # or open a pull request and merge it
```

Merging to `main` is all that is left to do: the pipeline creates the tag, the GitHub Release and the major alias.

| Change | Bump | Examples |
| --- | --- | --- |
| Fix, internal refactor, dependency/action update | **patch** `1.0.0 → 1.0.1` | corrected a shell step, Dependabot bump |
| New workflow, action, optional input or output | **minor** `1.0.0 → 1.1.0` | a new ecosystem, a new `with:` option |
| Anything that can break a caller on `@v1` | **major** `1.4.2 → 2.0.0` | renamed/removed input, new required secret, new `permissions` requirement, changed default behaviour |

What happens on each push to `main`:

| `VERSION` compared with the latest tag | Result |
| --- | --- |
| Higher (or no tag exists yet) | The sync check runs next to lint; if both pass the tag, release and alias are created. If either fails nothing is tagged and the next push retries |
| Equal, or its tag already exists | Lint still runs; nothing is released |
| Lower | Lint still runs; nothing is released (a note in the run summary) |
| Pre-release (`1.3.0-rc.1`) | Released as a GitHub *pre-release*; `@v1` is **not** moved to it |

A manual run (*Actions → _publish → Run workflow*) with **dry run** on shows what would be released without creating anything.

<a id="version-sync"></a>

## Keeping versions in sync

All versions in the repository must agree. `scripts/update-version.sh` is the only thing you need:

| Command | Effect |
| --- | --- |
| `scripts/update-version.sh --v=2.0.1` | Writes `VERSION`, then rewrites every `KMM-ZONE/open-flows/actions/<name>@v…` reference in `.github/workflows/*.yml` to `@v2.0.1`, and every major alias in the Markdown files to `@v2` |
| `scripts/update-version.sh --v=2.0.1 --dry-run` | Shows what would change, writes nothing |
| `scripts/update-version.sh --check` | Verifies that everything matches `VERSION`; exits non-zero and shows the offending lines otherwise |
| `scripts/update-version.sh --show` | Prints the current version |

Details:

- A version lower than the current one is refused unless you add `--force`.
- Pre-releases (`--v=3.0.0-rc.1`) update the workflow references to the exact pre-release but leave the README on the stable major alias.
- Exact references in prose (`…publish-npm.yml@v1.2.3`) are never touched; only major aliases are.
- `--check` runs in `lint.yml` on every change and as its own job (**verify-sync**) in `_publish.yml` before a release is created, so a release can never ship with mismatched references.

<a id="dependabot"></a>

## Dependabot and action versions

Every third-party `uses:` reference should be on the latest release of its action.

| Kind of action | Reference style | Example |
| --- | --- | --- |
| GitHub's own `actions/*` | latest **major tag** | `actions/checkout@v7` |
| Everything else (`pypa/…`, `ruby/…`, `gradle/…`, …) | **commit SHA** + version comment | `ruby/setup-ruby@be3c7df…  # v1.343.0` |
| This repository's own actions | **exact version**, managed by `update-version.sh` | `KMM-ZONE/open-flows/actions/verify-tag@v1.0.0` |

- [`.github/dependabot.yml`](../.github/dependabot.yml) checks **daily** and opens one grouped pull request. For SHA-pinned actions Dependabot rewrites both the SHA and the `# vX.Y.Z` comment. It ignores this repository's own actions.
- `lint.yml` also runs `scripts/check-actions-latest.sh`, which compares every third-party reference with the action's newest release and reports drift as a **warning**, so an outdated action is visible before Dependabot's pull request is merged. Run it with `STRICT=1` to make drift fail.
- **Merging a Dependabot pull request does not release anything**, because `VERSION` did not change. When you want consumers on `@v1` to get the update, run `scripts/update-version.sh --v=<next patch>` in the pull request or right after merging.
- In *your* repositories Dependabot will propose `@v1 → @v2` for these workflows when a new major is released – a good moment to read the release notes.
