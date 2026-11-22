# React Native

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-react-native.yml` · **Publishes to:** npm · **Auth:** `NPM_TOKEN`

Same as [npm](npm.md), tuned for libraries created with `create-react-native-library` / `react-native-builder-bob`: Yarn by default, plus `typecheck` and `lint` steps before the tests and the build.

**Secrets:** `NPM_TOKEN` (see the [secrets reference](../conventions.md#secrets-reference)).

## Caller workflow

```yaml
name: Publish React Native library
on:
  push:
    tags: ["v*.*.*"]

jobs:
  publish:
    permissions:
      contents: read
      id-token: write
    uses: KMM-ZONE/open-flows/.github/workflows/publish-react-native.yml@v1
    with:
      package_manager: yarn
      provenance: true
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## Inputs

Plus the [common inputs](../conventions.md#common-inputs).

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `node_version` | string | `24` | Node.js version |
| `package_manager` | string | `yarn` | Package manager used for installing dependencies: npm \| yarn \| pnpm |
| `install_directory` | string | `.` | Directory where dependencies are installed (workspace root for monorepos) |
| `registry_url` | string | `https://registry.npmjs.org` | Registry URL |
| `access` | string | `public` | Package access: public \| restricted |
| `dist_tag` | string | *(empty)* | npm dist-tag. Empty = latest, or the pre-release id (1.0.0-beta.1 -> beta, otherwise next) |
| `provenance` | boolean | `false` | Publish with provenance (public repos only; needs id-token: write in the caller) |
| `cache` | boolean | `true` | Cache the package manager store (needs a lock file) |
| `run_typecheck` | boolean | `true` | Run `npm run typecheck` (skipped when the script does not exist) |
| `run_lint` | boolean | `true` | Run `npm run lint` (skipped when the script does not exist) |
| `run_tests` | boolean | `true` | Run `npm run test` (skipped when the script does not exist) |
| `run_build` | boolean | `true` | Run `npm run build` (skipped when the script does not exist) |
| `publish_command` | string | *(empty)* | Custom publish command (e.g. 'pnpm publish --no-git-checks'). Empty = npm publish |
| `dry_run` | boolean | `false` | Run everything except the final upload (uses `npm publish --dry-run`) |

## Notes

- `typecheck`, `lint`, `test` and `build` scripts are run only if they exist in `package.json`.
- `bob build` normally runs from the `prepare` script, so installing dependencies already builds the library; the explicit `build` step is a no-op if you have no `build` script.
- Monorepo with an `example/` app: set `working_directory` to the library folder and keep `install_directory: "."`.
