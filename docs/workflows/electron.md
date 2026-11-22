# Electron

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-electron.yml` · **Publishes to:** npm and/or desktop installers attached to the GitHub Release · **Auth:** `NPM_TOKEN`, optional code-signing secrets

Three independent parts, switch each on or off:

1. **meta** – reads the version and checks the tag (always runs).
2. **npm** (`publish_npm: true`) – installs, tests, builds and publishes the package.
3. **installers** (`build_installers: true`) – builds with `electron-builder` on macOS, Windows and Linux and uploads the installers to the release of the tag.

## Secrets

| Secret | Required | Notes |
| --- | --- | --- |
| `NPM_TOKEN` | when `publish_npm` is `true` | |
| `CSC_LINK`, `CSC_KEY_PASSWORD` | no | Signing certificate and password (macOS, and Windows unless `WIN_CSC_LINK` is set) |
| `WIN_CSC_LINK`, `WIN_CSC_KEY_PASSWORD` | no | Windows certificate |
| `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID` | no | macOS notarization |

Without the signing secrets the installers are still built – unsigned.

## Caller workflow

Desktop app, installers only:

```yaml
name: Release Electron app
on:
  push:
    tags: ["v*.*.*"]

jobs:
  release:
    permissions:
      contents: write
      id-token: write
    uses: KMM-ZONE/open-flows/.github/workflows/publish-electron.yml@v1
    with:
      publish_npm: false
      build_installers: true
    secrets:
      CSC_LINK: ${{ secrets.CSC_LINK }}
      CSC_KEY_PASSWORD: ${{ secrets.CSC_KEY_PASSWORD }}
      APPLE_ID: ${{ secrets.APPLE_ID }}
      APPLE_APP_SPECIFIC_PASSWORD: ${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
      APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
      WIN_CSC_LINK: ${{ secrets.WIN_CSC_LINK }}
      WIN_CSC_KEY_PASSWORD: ${{ secrets.WIN_CSC_KEY_PASSWORD }}
```

Electron library published to npm:

```yaml
jobs:
  release:
    permissions: { contents: write, id-token: write }
    uses: KMM-ZONE/open-flows/.github/workflows/publish-electron.yml@v1
    with:
      publish_npm: true
      build_installers: false
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## Inputs

Plus the [common inputs](../conventions.md#common-inputs).

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `node_version` | string | `24` | Node.js version |
| `package_manager` | string | `npm` | npm \| yarn \| pnpm |
| `install_directory` | string | `.` | Directory where dependencies are installed (workspace root for monorepos) |
| `run_tests` | boolean | `true` | Run `npm run test` (skipped when the script does not exist) |
| `run_build` | boolean | `true` | Run `npm run build` (skipped when the script does not exist) |
| `publish_npm` | boolean | `true` | Publish the package to npm |
| `registry_url` | string | `https://registry.npmjs.org` | npm registry URL |
| `access` | string | `public` | npm access: public \| restricted |
| `dist_tag` | string | *(empty)* | npm dist-tag. Empty = latest, or the pre-release id (1.0.0-beta.1 -> beta, otherwise next) |
| `provenance` | boolean | `false` | Publish to npm with provenance (public repos only) |
| `build_installers` | boolean | `false` | Build desktop installers with electron-builder and attach them to the GitHub Release |
| `installer_os` | string | `["macos-latest","windows-latest","ubuntu-latest"]` | JSON array of runner labels to build installers on |
| `installer_command` | string | `npx electron-builder --publish never` | Command that produces the installers (must NOT publish by itself) |
| `dist_directory` | string | `dist` | Directory (relative to working_directory) where electron-builder writes installers |
| `dry_run` | boolean | `false` | Build everything but do not upload to npm or the GitHub Release |

## Notes

- `installer_command` must **not** publish by itself – use `--publish never` (the default does). The workflow uploads the files so that every OS attaches to the same release.
- `published` is `'true'` only when the npm upload happened; installers are reported in the release itself.
- Windows runners need Git Bash (preinstalled on GitHub-hosted runners).
