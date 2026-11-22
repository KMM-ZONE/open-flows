# Flutter

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-flutter.yml` · **Publishes to:** [pub.dev](https://pub.dev) · **Auth:** GitHub OIDC (no secret)

**One-time setup** (pub.dev must already know the package, so publish the very first version by hand with `dart pub publish`):

1. pub.dev → your package → **Admin** → *Automated publishing* → enable **GitHub Actions**.
2. Repository: `OWNER/REPO` of **your package repository** (not this one). Tag pattern: `v{{version}}`.

**Secrets:** none.

## Caller workflow

```yaml
name: Publish to pub.dev
on:
  push:
    tags: ["v[0-9]+.[0-9]+.[0-9]+*"]   # must match the tag pattern configured on pub.dev

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

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `flutter_version` | string | *(empty)* | Flutter SDK version, e.g. 3.38.1 (empty = latest of the channel) |
| `flutter_channel` | string | `stable` | Flutter channel |
| `dart_only` | boolean | `false` | Pure Dart package: use the Dart SDK (dart analyze / dart test) instead of Flutter |
| `runner` | string | `ubuntu-latest` | Runner label. Use macos-latest if the package needs Xcode tooling |
| `check_format` | boolean | `false` | Fail if `dart format` would change lib/ or test/ |
| `run_analyze` | boolean | `true` | Run static analysis |
| `run_tests` | boolean | `true` | Run tests (skipped automatically when there is no test/ directory) |
| `dry_run` | boolean | `false` | Run everything except the final upload (uses `pub publish --dry-run`) |

## Notes

- The package version must equal the tag (`version: 1.2.3` ↔ `v1.2.3`; build suffixes such as `1.2.3+4` must be in the tag too).
- `dart_only: true` switches to `dart analyze` / `dart test` for pure Dart packages and skips the Flutter SDK install.
- Use `runner: macos-latest` for plugins whose checks need Xcode. macOS minutes cost 10× Linux minutes.
