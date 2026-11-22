# Release tooling: check-version and create-release

[← README](../README.md) · [Documentation index](README.md)

Two actions for **any repository that keeps its version in a plain `VERSION` file**. This repository uses them to release itself (see [Releasing this repository](releasing.md#releasing-this-repository)).

The `VERSION` file contains just the number – `1.2.3`, or `1.3.0-rc.1` for a pre-release – with no leading `v`.

## What check-version decides

It compares `VERSION` with the highest existing semver tag using full [SemVer 2.0.0](https://semver.org) precedence (`1.10.0 > 1.9.0`, `1.0.0-rc.2 > 1.0.0-rc.1`, `1.0.0 > 1.0.0-rc.2`; build metadata is ignored). Tags that are not semver (aliases such as `v1`, or `nightly`) are ignored.

| `bumped` | `reason` | Meaning |
| --- | --- | --- |
| `true` | `first-release` | The repository has no semver tag yet |
| `true` | `bumped` | `VERSION` is higher than every existing tag |
| `false` | `same-version` | Equal to the latest tag (ignoring build metadata) |
| `false` | `tag-exists` | The tag for this exact version already exists |
| `false` | `lower-version` | Lower than the latest tag (for example a stale branch) |

## What create-release does

It creates the tag `vX.Y.Z` on the given commit and a GitHub Release with generated notes. It also keeps the **major alias** (`v1`) on the newest stable release of that major, and it is careful about order:

- a hotfix `1.0.1` released after `2.0.0` is **not** marked *Latest* and does not move `v1` if `1.1.0` already exists
- a pre-release (`2.0.0-rc.1`) is marked *pre-release*, never *Latest*, and never moves an alias
- it refuses to run if the tag already exists, or if `VERSION` at that commit differs from the requested version

The full inputs and outputs are in the [Actions reference](actions.md).

## Use them in your repository

```yaml
name: Release
on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0

      - id: version
        uses: KMM-ZONE/open-flows/actions/check-version@v1

      - if: steps.version.outputs.bumped == 'true'
        uses: KMM-ZONE/open-flows/actions/create-release@v1
        with:
          version: ${{ steps.version.outputs.version }}
```

Require a version bump on every pull request (the check fails when `VERSION` was not raised):

```yaml
name: Version bumped?
on: pull_request

jobs:
  version:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
      - uses: KMM-ZONE/open-flows/actions/check-version@v1
        with:
          require-bump: true
```

### Notes

- Tags and releases created with the built-in `GITHUB_TOKEN` **do not trigger other workflows** (a GitHub rule that prevents loops). If a tag-triggered publishing workflow must follow, call it in the same workflow with `needs:` instead of relying on `on: push: tags`.
- Moving the alias needs permission to update tags. If you protect tags with a ruleset, allow the *GitHub Actions* app to bypass it for the alias pattern (`v[0-9]*`).
- Do not keep the version in two places by hand. If your package manifest also carries a version, keep it equal to `VERSION` (or generate one from the other).
