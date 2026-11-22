# .NET

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-dotnet.yml` · **Publishes to:** NuGet (nuget.org or another feed) · **Auth:** `NUGET_API_KEY`

## Secrets

| Secret | Required | Notes |
| --- | --- | --- |
| `NUGET_API_KEY` | yes (not for `dry_run`) | Scope *Push*; glob pattern must cover your package ids |

## Caller workflow

```yaml
name: Publish to NuGet
on:
  push:
    tags: ["v*.*.*"]

jobs:
  publish:
    permissions:
      contents: read
    uses: KMM-ZONE/open-flows/.github/workflows/publish-dotnet.yml@v1
    with:
      dotnet_version: |
        8.0.x
        10.0.x
      version_from_tag: true      # tag v1.2.3 -> package version 1.2.3
    secrets:
      NUGET_API_KEY: ${{ secrets.NUGET_API_KEY }}
```

## Inputs

Plus the [common inputs](../conventions.md#common-inputs).

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `dotnet_version` | string | `10.0.x` | SDK version(s), one per line, e.g. '8.0.x' or '9.0.x' + newline + '10.0.x' |
| `project` | string | *(empty)* | Solution or project to restore/build/test/pack (empty = the one in working_directory) |
| `configuration` | string | `Release` | Build configuration |
| `version_from_tag` | boolean | `false` | On tag pushes, build and pack with -p:Version=`<tag without prefix>` (no version in the csproj needed) |
| `run_tests` | boolean | `true` | Run `dotnet test` |
| `test_args` | string | *(empty)* | Extra arguments for `dotnet test` |
| `nuget_source` | string | `https://api.nuget.org/v3/index.json` | NuGet push source URL |
| `dry_run` | boolean | `false` | Build, test and pack, but do not push |

## Notes

- With `version_from_tag: true` the version is passed as `-p:Version=…`, so you do not have to edit the `.csproj` for each release. Otherwise the version comes from the project (`<Version>`, MinVer, Nerdbank.GitVersioning – the checkout fetches tags).
- The workflow reads id and version of **every** `.nupkg` and, with `verify_tag`, fails if the tag does not match them all. Set `verify_tag: false` for solutions whose packages version independently.
- Re-runs are safe: `dotnet nuget push --skip-duplicate` leaves existing versions untouched (there is no separate `skip_if_published` input).
- The project must be packable (`<IsPackable>true</IsPackable>`). When you pack a **solution**, mark test and sample projects `<IsPackable>false</IsPackable>`, or point `project` at the specific `.csproj`.
- A matching `.snupkg` symbol package is pushed together with the `.nupkg`.
