# npm

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-npm.yml` · **Publishes to:** npmjs.com, or any npm registry (e.g. GitHub Packages) · **Auth:** `NPM_TOKEN`

## Secrets

| Secret | Required | Notes |
| --- | --- | --- |
| `NPM_TOKEN` | yes (not for `dry_run`) | See the [secrets reference](../conventions.md#secrets-reference) |

## Caller workflow

```yaml
name: Publish to npm
on:
  push:
    tags: ["v*.*.*"]

jobs:
  publish:
    permissions:
      contents: read
      id-token: write            # required by GitHub when provenance is enabled
    uses: KMM-ZONE/open-flows/.github/workflows/publish-npm.yml@v1
    with:
      node_version: "24"
      package_manager: pnpm      # npm | yarn | pnpm
      provenance: true           # public repositories only
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## Inputs

Plus the [common inputs](../conventions.md#common-inputs).

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `node_version` | string | `24` | Node.js version |
| `package_manager` | string | `npm` | Package manager used for installing dependencies: npm \| yarn \| pnpm |
| `install_directory` | string | `.` | Directory where dependencies are installed (workspace root for monorepos) |
| `registry_url` | string | `https://registry.npmjs.org` | Registry URL |
| `access` | string | `public` | Package access: public \| restricted |
| `dist_tag` | string | *(empty)* | npm dist-tag. Empty = latest, or the pre-release id (1.0.0-beta.1 -> beta, otherwise next) |
| `provenance` | boolean | `false` | Publish with provenance (public repos only; needs id-token: write in the caller) |
| `cache` | boolean | `true` | Cache the package manager store (needs a lock file) |
| `run_tests` | boolean | `true` | Run `npm run test` (skipped when the script does not exist) |
| `run_build` | boolean | `true` | Run `npm run build` (skipped when the script does not exist) |
| `publish_command` | string | *(empty)* | Custom publish command (e.g. 'pnpm publish --no-git-checks'). Empty = npm publish |
| `dry_run` | boolean | `false` | Run everything except the final upload (uses `npm publish --dry-run`) |

## Notes

- `npm run test` and `npm run build` run only if those scripts exist (`--if-present`).
- Pre-release versions get a matching dist-tag automatically (`1.0.0-beta.2` → `beta`, `2.0.0-0` → `next`), because npm refuses to publish a pre-release as `latest`.
- **Monorepo:** install at the workspace root and publish one package:
  `install_directory: "."`, `working_directory: packages/ui`, `tag_prefix: "ui-v"`.
- **GitHub Packages:** `registry_url: https://npm.pkg.github.com` and pass a personal access token with `write:packages` as `NPM_TOKEN`.
- pnpm workspaces that use the `workspace:` protocol should set `publish_command: "pnpm publish --no-git-checks"`.
