# Rust

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-cargo.yml` · **Publishes to:** [crates.io](https://crates.io) · **Auth:** `CARGO_REGISTRY_TOKEN`

## Secrets

| Secret | Required |
| --- | --- |
| `CARGO_REGISTRY_TOKEN` | yes (not for `dry_run`) |

## Caller workflow

```yaml
name: Publish to crates.io
on:
  push:
    tags: ["v*.*.*"]

jobs:
  publish:
    permissions:
      contents: read
    uses: KMM-ZONE/open-flows/.github/workflows/publish-cargo.yml@v1
    with:
      run_clippy: true
      test_args: --all-features
    secrets:
      CARGO_REGISTRY_TOKEN: ${{ secrets.CARGO_REGISTRY_TOKEN }}
```

Workspace with dependent crates – publish them in order, one job each:

```yaml
jobs:
  core:
    uses: KMM-ZONE/open-flows/.github/workflows/publish-cargo.yml@v1
    with: { package: my-core }
    secrets: { CARGO_REGISTRY_TOKEN: "${{ secrets.CARGO_REGISTRY_TOKEN }}" }
  cli:
    needs: core
    uses: KMM-ZONE/open-flows/.github/workflows/publish-cargo.yml@v1
    with: { package: my-cli }
    secrets: { CARGO_REGISTRY_TOKEN: "${{ secrets.CARGO_REGISTRY_TOKEN }}" }
```

## Inputs

Plus the [common inputs](../conventions.md#common-inputs).

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `toolchain` | string | `stable` | Rust toolchain (stable, beta, nightly, 1.85, ...) |
| `package` | string | *(empty)* | Crate to publish from a workspace (cargo -p). Empty = the only/first package |
| `run_tests` | boolean | `true` | Run `cargo test` |
| `test_args` | string | *(empty)* | Extra arguments for `cargo test`, e.g. --all-features |
| `run_clippy` | boolean | `false` | Run `cargo clippy -- -D warnings` |
| `allow_dirty` | boolean | `false` | Pass --allow-dirty to cargo publish (needed when Cargo.lock is generated and not committed) |
| `dry_run` | boolean | `false` | Run `cargo publish --dry-run` instead of publishing |

## Notes

- Name and version come from `cargo metadata`; `package` selects a crate in a workspace.
- Cargo refuses to publish from a dirty working tree. If `Cargo.lock` is generated during the run and not committed, set `allow_dirty: true`.
- `crates.io` versions cannot be overwritten, only yanked.
- A crate needs `description` and `license` (or `license-file`) in `Cargo.toml`.
