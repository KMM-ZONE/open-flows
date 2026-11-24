# Flutter

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-flutter.yml` · **Publishes to:** [pub.dev](https://pub.dev) · **Auth:** GitHub OIDC (no secret)

**One-time setup** (pub.dev must already know the package, so publish the very first version by hand with `dart pub publish`):

1. pub.dev → your package → **Admin** → _Automated publishing_ → enable **GitHub Actions**.
2. Repository: `OWNER/REPO` of **your package repository** (not this one). Tag pattern: `v{{version}}`.

**Secrets:** none.

## Caller workflow

```yaml
name: Publish to pub.dev
on:
  push:
    tags: ["v[0-9]+.[0-9]+.[0-9]+*"] # must match the tag pattern configured on pub.dev

jobs:
  publish:
    permissions:
      contents: read
      id-token: write
    uses: KMM-ZONE/open-flows/.github/workflows/publish-flutter.yml@v1
    with:
      flutter_channel: stable
      check_format: true
```

Monorepo – one package per folder, tags like `my_pkg-v1.2.3` (pub.dev tag pattern `my_pkg-v{{version}}`):

```yaml
on:
  push:
    tags: ["my_pkg-v[0-9]+.[0-9]+.[0-9]+*"]
jobs:
  publish:
    permissions: { contents: read, id-token: write }
    uses: KMM-ZONE/open-flows/.github/workflows/publish-flutter.yml@v1
    with:
      working_directory: packages/my_pkg
      tag_prefix: "my_pkg-v"
```

## Inputs

Plus the [common inputs](../conventions.md#common-inputs).

| Input             | Type    | Default         | Description                                                                                                    |
| ----------------- | ------- | --------------- | -------------------------------------------------------------------------------------------------------------- |
| `flutter_version` | string  | _(empty)_       | Flutter SDK version, e.g. 3.38.1 (empty = latest of the channel)                                               |
| `flutter_channel` | string  | `stable`        | Flutter channel                                                                                                |
| `dart_only`       | boolean | `false`         | Pure Dart package: use the Dart SDK (dart analyze / dart test) instead of Flutter                              |
| `runner`          | string  | `ubuntu-latest` | Runner label. Use macos-latest if the package needs Xcode tooling                                              |
| `check_format`    | boolean | `false`         | Fail if `dart format` would change the folders listed in format_paths                                          |
| `format_paths`    | string  | `lib test`      | Space-separated folders checked by `dart format` (folders that do not exist are skipped)                       |
| `run_analyze`     | boolean | `true`          | Run static analysis                                                                                            |
| `analyze_paths`   | string  | _(empty)_       | Space-separated paths for the analyzer, e.g. `lib test` (empty = the whole package; missing paths are skipped) |
| `run_tests`       | boolean | `true`          | Run tests (skipped automatically when there is no test/ directory)                                             |
| `dry_run`         | boolean | `false`         | Run everything except the final upload (uses `pub publish --dry-run`)                                          |

## Notes

- The package version must equal the tag (`version: 1.2.3` ↔ `v1.2.3`; build suffixes such as `1.2.3+4` must be in the tag too).
- `dart_only: true` switches to `dart analyze` / `dart test` for pure Dart packages and skips the Flutter SDK install.
- Use `runner: macos-latest` (or a fixed image such as `macos-15`) for plugins whose checks need Xcode. macOS minutes cost 10× Linux minutes.
- **Analyzing only some folders.** By default the whole package is analyzed. If your package has an `example/` app that is not set up in CI, set `analyze_paths: lib test` (folders that do not exist are skipped). `format_paths` does the same for the format check and defaults to `lib test`.

---

## Creating the tag and the release

`publish-flutter.yml` runs when a tag is pushed. To create that tag (and the GitHub Release) from a manual run, use [`check-version`](../actions.md#check-version) and [`github-release`](../actions.md#github-release): `check-version` reads the version straight from `pubspec.yaml`, decides whether it is newer than the latest tag, and `github-release` creates the release.

```yaml
name: Create Release
run-name: Create Release for v${{ inputs.version }}

on:
  workflow_dispatch:
    inputs:
      version:
        description: Package version from pubspec.yaml, without the v prefix
        required: true
        type: string

permissions:
  contents: write

concurrency:
  group: create-release
  cancel-in-progress: false

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
        with:
          ref: main
          token: ${{ secrets.RELEASE_TOKEN }}
          fetch-depth: 0

      - id: version
        uses: KMM-ZONE/open-flows/actions/check-version@v1
        with:
          version-file: pubspec.yaml

      - name: The requested version must match pubspec.yaml
        env:
          REQUESTED: ${{ inputs.version }}
          ACTUAL: ${{ steps.version.outputs.version }}
        run: |
          if [ "$REQUESTED" != "$ACTUAL" ]; then
            echo "::error::Requested $REQUESTED but pubspec.yaml says $ACTUAL"
            exit 1
          fi

      - name: Create and push the tag
        if: steps.version.outputs.bumped == 'true'
        env:
          TAG: ${{ steps.version.outputs.tag }}
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git tag -a "$TAG" -m "Release $TAG"
          git push origin "$TAG"

      - name: Create the GitHub Release
        if: steps.version.outputs.bumped == 'true'
        uses: KMM-ZONE/open-flows/actions/github-release@v1
        with:
          tag: ${{ steps.version.outputs.tag }}
          version: ${{ steps.version.outputs.version }}
          title: my_package ${{ steps.version.outputs.tag }}
          token: ${{ secrets.RELEASE_TOKEN }}
```

The tag is pushed with a **personal access token** (`RELEASE_TOKEN`, a fine-grained token with _Contents: Read and write_) because a tag pushed with the default `GITHUB_TOKEN` does not start other workflows, so the publish workflow would never run.

Not bumped (the version in `pubspec.yaml` is not newer than the latest tag)? Nothing is created and the run summary says why. Add `require-bump: true` to `check-version` if you would rather the run fail.
