# Unreal Engine

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-unreal.yml` · **Publishes to:** a GitHub Release (zip per engine version / platform) · **Secrets:** none

> **Two hard limits.** (1) GitHub-hosted runners cannot hold an Unreal Engine install, so this workflow runs on a **self-hosted runner** that already has the engine. (2) **Fab has no public upload API** – you upload the produced zip in the Fab Publisher Portal by hand, once per engine version.

It reads `VersionName` from your `.uplugin`, verifies the tag, runs `RunUAT BuildPlugin`, zips the result as `<Plugin>-<version>-UE<engine>-<OS>.zip`, and attaches it to the release.

**Runner requirements:** Unreal Engine installed at `engine_path`, Git Bash (Windows), `jq`, `zip` (macOS/Linux), and the `gh` CLI if `github_release` is on.

## Caller workflow

```yaml
name: Package Unreal plugin
on:
  push:
    tags: ["v*.*.*"]

jobs:
  package:
    permissions:
      contents: write
    uses: KMM-ZONE/open-flows/.github/workflows/publish-unreal.yml@v1
    with:
      runner_labels: '["self-hosted","windows","unreal"]'
      engine_path: "C:/Program Files/Epic Games/UE_5.6"
      engine_version: "5.6"
      target_platforms: Win64
```

Several engine versions – one call per runner/engine pair:

```yaml
jobs:
  ue56:
    permissions: { contents: write }
    uses: KMM-ZONE/open-flows/.github/workflows/publish-unreal.yml@v1
    with:
      runner_labels: '["self-hosted","ue56"]'
      engine_path: /opt/UE_5.6
      engine_version: "5.6"
  ue57:
    permissions: { contents: write }
    uses: KMM-ZONE/open-flows/.github/workflows/publish-unreal.yml@v1
    with:
      runner_labels: '["self-hosted","ue57"]'
      engine_path: /opt/UE_5.7
      engine_version: "5.7"
```

## Inputs

Plus the [common inputs](../conventions.md#common-inputs); `skip_if_published` and `working_directory` do not apply.

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `runner_labels` | string | `["self-hosted"]` | JSON array of runner labels, e.g. ["self-hosted","windows","unreal"] |
| `engine_path` | string | **required** | Unreal Engine root on the runner (the folder that contains Engine/), e.g. C:/Program Files/Epic Games/UE_5.6 |
| `engine_version` | string | *(empty)* | Engine version label used in the zip name, e.g. 5.6 |
| `uplugin` | string | *(empty)* | Path to the .uplugin relative to the repo root (empty = the first .uplugin found) |
| `target_platforms` | string | `Win64` | BuildPlugin -TargetPlatforms value, '+' separated (e.g. Win64+Linux) |
| `extra_args` | string | *(empty)* | Extra arguments appended to the BuildPlugin command |
| `lfs` | boolean | `false` | Fetch Git LFS files |
| `github_release` | boolean | `true` | Attach the zip to the GitHub Release of the tag (needs the gh CLI on the runner) |
| `dry_run` | boolean | `false` | Build and zip, but do not touch the GitHub Release |

## Notes

- The `.uplugin` needs a `VersionName` (it is the version compared with the tag).
- The workflow only builds the plugin. Packaging a **game project** needs your own `RunUAT BuildCookRun` command.
