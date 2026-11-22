# Swift / iOS

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-swift.yml` · **Publishes to:** SwiftPM (**a git tag is the release**), optionally CocoaPods · **Secrets:** none for SwiftPM

Swift Package Manager resolves versions from git tags, so there is no upload. The workflow validates the tag, resolves, builds and tests on macOS, optionally pushes your podspec to CocoaPods trunk, and creates the GitHub Release.

## Secrets

| Secret | Required |
| --- | --- |
| `COCOAPODS_TRUNK_TOKEN` | only when `podspec` is set |

## Caller workflow

```yaml
name: Release Swift package
on:
  push:
    tags: ["*.*.*", "v*.*.*"]

jobs:
  release:
    permissions:
      contents: write
    uses: KMM-ZONE/open-flows/.github/workflows/publish-swift.yml@v1
    with:
      xcode_version: "16.4"
      # iOS-only package? also test with xcodebuild:
      # xcodebuild_scheme: MyPackage
      # podspec: MyPackage.podspec
    # secrets:
    #   COCOAPODS_TRUNK_TOKEN: ${{ secrets.COCOAPODS_TRUNK_TOKEN }}
```

## Inputs

Plus the [common inputs](../conventions.md#common-inputs); `verify_tag` and `skip_if_published` do not apply.

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `runner` | string | `macos-15` | macOS runner label |
| `xcode_version` | string | *(empty)* | Xcode version to select, e.g. 16.4 (empty = runner default) |
| `tag` | string | *(empty)* | Existing tag to release (for workflow_dispatch). Empty = the tag that triggered the run |
| `tag_prefix` | string | *(empty)* | Optional text before the version in the tag (a leading v is always accepted) |
| `run_tests` | boolean | `true` | Run `swift test` |
| `build_args` | string | *(empty)* | Extra arguments for `swift build` |
| `test_args` | string | *(empty)* | Extra arguments for `swift test` |
| `xcodebuild_scheme` | string | *(empty)* | Also run `xcodebuild test` for this scheme (needed for iOS-only packages). Empty = skip |
| `xcodebuild_destination` | string | `platform=iOS Simulator,name=iPhone 16` | Destination for xcodebuild test |
| `podspec` | string | *(empty)* | Path to a .podspec to push to CocoaPods trunk. Empty = SwiftPM only |
| `github_release` | boolean | `true` | Create a GitHub Release with generated notes (skipped when it already exists) |
| `dry_run` | boolean | `false` | Build and test only (podspec is linted, nothing is pushed or released) |

## Notes

- Tags may or may not start with `v`; the rest must be `MAJOR.MINOR.PATCH[-pre]`.
- With a `podspec`, its version must equal the tag version, or the run fails before pushing.
- macOS minutes cost 10× Linux minutes on GitHub-hosted runners. `xcode_version` must be installed on the chosen `runner` image.
- Releasing an existing tag by hand: `workflow_dispatch` with `tag: 1.2.3`.
