# Go

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-go.yml` · **Publishes to:** the Go module ecosystem – **the git tag is the release** · **Secrets:** none

There is nothing to upload: `go get` resolves versions from your repository's tags through `proxy.golang.org`. This workflow therefore:

1. checks the tag is `vMAJOR.MINOR.PATCH[-pre]`, and – for v2 and above – that your module path ends in `/vN`
2. runs `go vet`, `go build` and `go test`
3. asks `proxy.golang.org` for the new version so `go get` and pkg.go.dev see it immediately
4. creates the GitHub Release with generated notes (skipped if one already exists)

## Caller workflow

```yaml
name: Release Go module
on:
  push:
    tags: ["v*.*.*"]

jobs:
  release:
    permissions:
      contents: write
    uses: KMM-ZONE/open-flows/.github/workflows/publish-go.yml@v1
    with:
      test_args: -race ./...
```

Module in a sub-directory (`github.com/me/repo/tools`, tags like `tools/v1.2.0`):

```yaml
on:
  push:
    tags: ["tools/v*.*.*"]
jobs:
  release:
    permissions: { contents: write }
    uses: KMM-ZONE/open-flows/.github/workflows/publish-go.yml@v1
    with:
      working_directory: tools
      tag_prefix: "tools/"
```

## Inputs

Plus the [common inputs](../conventions.md#common-inputs); `verify_tag` and `skip_if_published` do not apply – the tag *is* the version.

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `go_version` | string | *(empty)* | Go version (empty = the version in go.mod) |
| `tag` | string | *(empty)* | Existing tag to release (for workflow_dispatch). Empty = the tag that triggered the run |
| `tag_prefix` | string | *(empty)* | Text before the 'v' in the tag. Empty for v1.2.3; 'sub/dir/' for sub-module tags like sub/dir/v1.2.3 |
| `run_vet` | boolean | `true` | Run `go vet` |
| `run_tests` | boolean | `true` | Run `go test` |
| `test_args` | string | `./...` | Arguments for `go test` |
| `warm_proxy` | boolean | `true` | Request the new version from proxy.golang.org so it is indexed right away |
| `github_release` | boolean | `true` | Create a GitHub Release with generated notes (skipped when it already exists) |
| `dry_run` | boolean | `false` | Validate, vet and test only |

## Notes

- `tag_prefix` here is the text **before the `v`** (empty by default), because Go requires the `v`.
- Releasing an existing tag by hand: run the workflow with `workflow_dispatch` and pass `tag: v1.2.3`.
- Private repositories cannot be fetched by the public proxy – set `warm_proxy: false`.
- The `published` output is `'true'` when the proxy was warmed or the release created.
