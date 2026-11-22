# Unity

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-unity.yml` · **Publishes to:** npm and/or NuGet, plus a GitHub Release · **Auth:** `NPM_TOKEN`, `NUGET_API_KEY`

> **The Unity Asset Store has no upload API.** This workflow tests and packs your package and attaches the `.tgz` to the GitHub Release (and the workflow run); you upload it in the Asset Store **Publisher Portal** yourself. [OpenUPM](https://openupm.com) needs no CI at all – it builds from your git tags after you add the package to its list.

What it does: reads the UPM `package.json`, verifies the tag, optionally runs Unity tests with [game-ci](https://game.ci), runs `npm pack`, optionally publishes the tarball to an npm registry (Unity's scoped registries) and a NuGet package, and creates the release.

## Secrets

| Secret | Required |
| --- | --- |
| `NPM_TOKEN` | when `publish_npm: true` |
| `NUGET_API_KEY` | when `publish_nuget: true` |
| `UNITY_LICENSE`, `UNITY_EMAIL`, `UNITY_PASSWORD` (`UNITY_SERIAL` for Plus/Pro) | only when `run_tests: true` |

## Caller workflow

```yaml
name: Release Unity package
on:
  push:
    tags: ["v*.*.*"]

jobs:
  release:
    permissions:
      contents: write
    uses: KMM-ZONE/open-flows/.github/workflows/publish-unity.yml@v1
    with:
      package_path: Packages/com.company.tools
      project_path: TestProject
      run_tests: true
      publish_npm: true
      publish_nuget: false
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
      UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}
      UNITY_EMAIL: ${{ secrets.UNITY_EMAIL }}
      UNITY_PASSWORD: ${{ secrets.UNITY_PASSWORD }}
```

## Inputs

Plus the [common inputs](../conventions.md#common-inputs); `skip_if_published` and `working_directory` do not apply.

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `package_path` | string | `.` | Folder containing the UPM package.json (e.g. . or Packages/com.company.pkg) |
| `project_path` | string | `.` | Unity project used to run tests (a test project that references the package) |
| `unity_version` | string | `auto` | Unity version, or 'auto' to read ProjectSettings/ProjectVersion.txt |
| `lfs` | boolean | `false` | Fetch Git LFS files |
| `run_tests` | boolean | `false` | Run Unity tests with game-ci (needs the UNITY_* secrets) |
| `test_mode` | string | `all` | editmode \| playmode \| all |
| `publish_npm` | boolean | `false` | Publish the UPM package to an npm registry (scoped registry for the Unity Package Manager) |
| `npm_registry` | string | `https://registry.npmjs.org` | npm registry URL |
| `npm_access` | string | `public` | npm access: public \| restricted |
| `publish_nuget` | boolean | `false` | Pack nuget_project and push it to NuGet |
| `nuget_project` | string | *(empty)* | Path to the .csproj to pack for NuGet (required when publish_nuget is true) |
| `nuget_source` | string | `https://api.nuget.org/v3/index.json` | NuGet push source URL |
| `dotnet_version` | string | `9.0.x` | .NET SDK used for NuGet packing |
| `github_release` | boolean | `true` | Create a GitHub Release and attach the .tgz (and .nupkg) |
| `dry_run` | boolean | `false` | Test and pack only; nothing is published or released |

## Notes

- NuGet is for the .NET parts of a Unity package (NuGetForUnity-style): point `nuget_project` at a `.csproj`; it is packed with `-p:Version=<package.json version>`.
- Test runs use Docker images from game-ci and can take a long time; the job has a 2-hour limit.
- Not publishing anywhere? Leave both `publish_*` off – you still get tests, the tarball and the release.
