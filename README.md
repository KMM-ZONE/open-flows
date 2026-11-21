# Open Flows

[![Release](https://img.shields.io/github/v/release/KMM-ZONE/open-flows?label=release)](https://github.com/KMM-ZONE/open-flows/releases)
[![Lint](https://github.com/KMM-ZONE/open-flows/actions/workflows/lint.yml/badge.svg)](https://github.com/KMM-ZONE/open-flows/actions/workflows/lint.yml)

**Open Flows** is the public collection of reusable GitHub Actions workflows and composite actions maintained by **[KMM-ZONE](https://kmm.zone)** (kmm.zone).
Anyone can call them from any repository – public or private – with a few lines of YAML, instead of copying a 100-line pipeline into every project.

- 📦 **Publishing workflows** – one per ecosystem (**17 ecosystems, 18 workflows**), identical inputs and outputs everywhere
- 🧩 **Reusable actions** – the building blocks of those workflows live in [`actions/`](#actions) as small composite actions with kebab-case names. Use them on their own in any workflow
- 🏷️ **Release tooling** – [`check-version` and `create-release`](#release-tooling), driven by a plain `VERSION` file. This repository releases itself with them
- 🔐 **Public code, private credentials** – nothing is downloaded from an external service; the only secrets involved are the ones _you_ store in _your_ repository
- ✅ A release is a pushed tag. The publishing workflows refuse to publish when the tag and the manifest version disagree
- 🧪 Every workflow has `dry_run`, and skips versions that are already published (re-runs are safe)
- 📌 Always current: GitHub's own `actions/*` use the latest major tag, third-party actions are pinned to commit SHAs, and Dependabot checks both daily

**Using it:** call a workflow as `KMM-ZONE/open-flows/.github/workflows/publish-npm.yml@v1` or an action as `KMM-ZONE/open-flows/actions/verify-tag@v1`. The `@v1` alias follows every compatible update; `@v1.2.3` or a full commit SHA is fully reproducible. See [Releasing this repository](#releasing-this-repository) for how versions are produced.

## Contents

- [Quick start](#quick-start)
- [Supported ecosystems and the secrets they need](#supported-ecosystems)
- [Conventions shared by every workflow](#conventions)
  - [Inputs and outputs](#common-inputs)
  - [Permissions](#permissions)
  - [Passing secrets](#passing-secrets)
  - [Dry runs](#dry-runs)
  - [Why tokens and not OIDC](#why-tokens)
  - [Secrets reference](#secrets-reference)
- [Publishing workflows](#publishing-workflows):
  [Flutter](#flutter) ·
  [npm](#npm) ·
  [React Native](#react-native) ·
  [Electron](#electron) ·
  [Python](#python) ·
  [Django](#django) ·
  [.NET](#dotnet) ·
  [Maven](#maven) ·
  [Gradle](#gradle) ·
  [Rust](#rust) ·
  [Go](#go) ·
  [PHP / Composer](#php) ·
  [Laravel](#laravel) ·
  [Ruby](#ruby) ·
  [Swift / iOS](#swift) ·
  [Unity](#unity) ·
  [Unreal Engine](#unreal) ·
  [WordPress](#wordpress)
- [Actions](#actions)
- [Release tooling: check-version and create-release](#release-tooling)
- [Migrating existing per-repo pipelines](#migrating)
- [Security notes](#security-notes)
- [Troubleshooting](#troubleshooting)
- [Maintaining this repository](#maintaining):
  [Releasing](#releasing-this-repository) ·
  [Keeping versions in sync](#version-sync) ·
  [Dependabot and action versions](#dependabot) ·
  [Linting and warnings](#linting)

---

<a id="quick-start"></a>

## Quick start

**1. Add the secrets** your ecosystem needs (see the table below) to the repository you want to publish from – or once for your whole organisation:
_Settings → Secrets and variables → Actions → New repository secret_.

**2. Add a caller workflow** to that repository, for example `.github/workflows/release.yml`:

```yaml
name: Release
on:
  push:
    tags: ["v*.*.*"]

jobs:
  publish:
    permissions:
      contents: read
      id-token: write # only needed by npm / React Native / Electron / Flutter
    uses: KMM-ZONE/open-flows/.github/workflows/publish-npm.yml@v1
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**3. Release** – bump the version in your manifest (`package.json`, `pubspec.yaml`, `pyproject.toml`, …), commit, then tag and push:

```bash
git tag v1.2.3
git push origin v1.2.3
```

The workflow verifies that tag `v1.2.3` equals the manifest version `1.2.3`, runs your tests, builds and publishes.

---

<a id="supported-ecosystems"></a>

## Supported ecosystems

| Ecosystem                         | Workflow file              | Publishes to                                              | Secrets you need to add                                                                                                                                                                     |
| --------------------------------- | -------------------------- | --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Flutter / Dart](#flutter)        | `publish-flutter.yml`      | pub.dev                                                   | **None** – uses pub.dev automated publishing (GitHub OIDC)                                                                                                                                  |
| [Node.js (npm)](#npm)             | `publish-npm.yml`          | npmjs.com or any npm registry                             | `NPM_TOKEN`                                                                                                                                                                                 |
| [React Native](#react-native)     | `publish-react-native.yml` | npm                                                       | `NPM_TOKEN`                                                                                                                                                                                 |
| [Electron](#electron)             | `publish-electron.yml`     | npm + installers on the GitHub Release                    | `NPM_TOKEN` · optional signing: `CSC_LINK`, `CSC_KEY_PASSWORD`, `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID`, `WIN_CSC_LINK`, `WIN_CSC_KEY_PASSWORD`                          |
| [Python](#python)                 | `publish-python.yml`       | PyPI / TestPyPI                                           | `PYPI_API_TOKEN`                                                                                                                                                                            |
| [Django](#django)                 | `publish-django.yml`       | PyPI (after a Python × Django test matrix)                | `PYPI_API_TOKEN`                                                                                                                                                                            |
| [.NET](#dotnet)                   | `publish-dotnet.yml`       | NuGet                                                     | `NUGET_API_KEY`                                                                                                                                                                             |
| [Java / Kotlin – Maven](#maven)   | `publish-maven.yml`        | Maven Central (Central Portal)                            | `MAVEN_CENTRAL_USERNAME`, `MAVEN_CENTRAL_PASSWORD`, `GPG_PRIVATE_KEY`, `GPG_PASSPHRASE`                                                                                                     |
| [Java / Kotlin – Gradle](#gradle) | `publish-gradle.yml`       | Maven Central or Gradle Plugin Portal                     | Central: `MAVEN_CENTRAL_USERNAME`, `MAVEN_CENTRAL_PASSWORD`, `SIGNING_KEY`, `SIGNING_PASSWORD` (+ optional `SIGNING_KEY_ID`) · Plugin Portal: `GRADLE_PUBLISH_KEY`, `GRADLE_PUBLISH_SECRET` |
| [Rust](#rust)                     | `publish-cargo.yml`        | crates.io                                                 | `CARGO_REGISTRY_TOKEN`                                                                                                                                                                      |
| [Go](#go)                         | `publish-go.yml`           | Go module proxy (a git tag _is_ the release)              | **None**                                                                                                                                                                                    |
| [PHP / Composer](#php)            | `publish-composer.yml`     | Packagist                                                 | `PACKAGIST_USERNAME`, `PACKAGIST_API_TOKEN` _(optional when the Packagist GitHub hook is active)_                                                                                           |
| [Laravel](#laravel)               | `publish-laravel.yml`      | Packagist (after a PHP × Laravel test matrix)             | `PACKAGIST_USERNAME`, `PACKAGIST_API_TOKEN` _(optional, as above)_                                                                                                                          |
| [Ruby](#ruby)                     | `publish-rubygems.yml`     | RubyGems.org                                              | `RUBYGEMS_API_KEY`                                                                                                                                                                          |
| [Swift / iOS](#swift)             | `publish-swift.yml`        | SwiftPM (a git tag) + optional CocoaPods + GitHub Release | **None** for SwiftPM · `COCOAPODS_TRUNK_TOKEN` for CocoaPods                                                                                                                                |
| [Unity](#unity)                   | `publish-unity.yml`        | npm / NuGet / GitHub Release. **Asset Store is manual**   | `NPM_TOKEN` and/or `NUGET_API_KEY` · optional tests: `UNITY_LICENSE`, `UNITY_EMAIL`, `UNITY_PASSWORD` (`UNITY_SERIAL` for Plus/Pro)                                                         |
| [Unreal Engine](#unreal)          | `publish-unreal.yml`       | GitHub Release zip. **Fab is manual**                     | **None** (needs a self-hosted runner with the engine)                                                                                                                                       |
| [WordPress](#wordpress)           | `publish-wordpress.yml`    | WordPress.org plugin repository (SVN)                     | `SVN_USERNAME`, `SVN_PASSWORD`                                                                                                                                                              |

`GITHUB_TOKEN` is created automatically for every run – it is never something you add yourself.

> **Three registries have no upload API.** Go and Swift Package Manager publish by _git tag_, so those workflows validate and index rather than upload. The Unity Asset Store and Fab (Unreal) have no public upload API at all, so those workflows produce the artefact and you upload it in the vendor's portal. Details are in each section.

---

<a id="conventions"></a>

## Conventions shared by every workflow

<a id="common-inputs"></a>

### Inputs and outputs

These inputs behave the same in every workflow where they exist (each section's table lists only the inputs that are specific to that workflow or have a different default, plus `dry_run`, because what exactly it skips varies):

| Input               | Default | Meaning                                                                                                |
| ------------------- | ------- | ------------------------------------------------------------------------------------------------------ |
| `working_directory` | `.`     | Folder of the package inside the repository (monorepos)                                                |
| `verify_tag`        | `true`  | On tag pushes, fail unless the tag equals `tag_prefix` + the version found in the manifest             |
| `tag_prefix`        | `v`     | Text in front of the version in your tags (`v1.2.3` → `v`). For monorepos use e.g. `my_pkg-v`          |
| `skip_if_published` | `true`  | If the exact version is already on the registry, finish successfully without publishing (safe re-runs) |
| `dry_run`           | `false` | Run everything except the final upload                                                                 |

Every workflow exposes the same two outputs:

| Output      | Meaning                                                                                          |
| ----------- | ------------------------------------------------------------------------------------------------ |
| `version`   | The version that was released (read from the manifest, or from the tag for tag-based ecosystems) |
| `published` | `'true'` only when this run actually uploaded something                                          |

```yaml
jobs:
  publish:
    uses: KMM-ZONE/open-flows/.github/workflows/publish-python.yml@v1
    secrets:
      PYPI_API_TOKEN: ${{ secrets.PYPI_API_TOKEN }}

  announce:
    needs: publish
    if: needs.publish.outputs.published == 'true'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Released ${{ needs.publish.outputs.version }}"
```

<a id="permissions"></a>

### Permissions

A reusable workflow can never receive more permissions than its caller grants, so set `permissions` on the job that calls it:

| Workflow                 | `contents` | `id-token` | Why                                                                     |
| ------------------------ | ---------- | ---------- | ----------------------------------------------------------------------- |
| Flutter                  | `read`     | `write`    | pub.dev OIDC login                                                      |
| npm, React Native        | `read`     | `write`    | only used when `provenance: true`; the permission must still be granted |
| Electron                 | `write`    | `write`    | installers are attached to the release; npm provenance                  |
| Go, Swift, Unity, Unreal | `write`    | –          | creates / updates the GitHub Release                                    |
| everything else          | `read`     | –          |                                                                         |

If a run fails immediately with _"requesting 'id-token: write', but is only allowed 'id-token: none'"_, the calling job is missing the permission.

<a id="passing-secrets"></a>

### Passing secrets

Secrets are **not** passed to a reusable workflow automatically. Either map them explicitly (recommended – the call shows exactly what is shared):

```yaml
secrets:
  NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

or share everything with `secrets: inherit` (only for repositories in the same organisation/enterprise as the workflow's repository, i.e. not for a public central repo used by other owners).

Every secret is optional at the _workflow_ level. A workflow checks the ones it needs at the start of a real run and fails with a clear message when one is missing, so a `dry_run` works without any secrets.

<a id="dry-runs"></a>

### Dry runs

Add a manual trigger with a `dry_run` switch to rehearse a release (install, test, build, package-check, no upload):

```yaml
on:
  push:
    tags: ["v*.*.*"]
  workflow_dispatch:
    inputs:
      dry_run:
        description: "Rehearse the release without publishing"
        type: boolean
        default: true

jobs:
  publish:
    uses: KMM-ZONE/open-flows/.github/workflows/publish-npm.yml@v1
    with:
      dry_run: ${{ inputs.dry_run || false }}
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

<a id="why-tokens"></a>

### Why tokens and not OIDC ("trusted publishing")

OIDC publishing is nicer than long-lived tokens, but most registries match the identity of the workflow _file_. When that file lives in this central repo instead of yours, the match fails:

| Registry                                           | Trusted publishing from a **reusable** workflow                                                   | Used here                           |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ----------------------------------- |
| pub.dev                                            | ✅ Works – it matches repository and tag pattern. Dart's own docs recommend a reusable workflow   | OIDC, no secret                     |
| PyPI                                               | ❌ PyPI documents that reusable workflows cannot be the trusted workflow                          | `PYPI_API_TOKEN`                    |
| npm                                                | ⚠️ npm validates the _calling_ workflow's file name, and allows one trusted publisher per package | `NPM_TOKEN` (+ optional provenance) |
| NuGet                                              | ⚠️ The OIDC claim names the reusable workflow, so it does not match your repository               | `NUGET_API_KEY`                     |
| crates.io, RubyGems                                | Not verified for reusable workflows                                                               | tokens                              |
| Maven Central, Packagist, WordPress.org, CocoaPods | No OIDC publishing                                                                                | tokens / passwords                  |

If you want OIDC for PyPI or npm anyway, copy the publish job into a workflow file inside your own repository – then it works, at the price of not being centralized.

<a id="secrets-reference"></a>

### Secrets reference

| Secret                                                              | Used by                            | Where to create it                                                                                                                                                                                                                                                                                          |
| ------------------------------------------------------------------- | ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `NPM_TOKEN`                                                         | npm, React Native, Electron, Unity | npmjs.com → profile → **Access Tokens** → Generate New Token → _Granular_ with **Read and write** on the package/scope. If your account enforces 2FA for publishing, enable the option that lets the token skip the one-time-password prompt, otherwise CI fails with `EOTP`. Tokens expire – note the date |
| `PYPI_API_TOKEN`                                                    | Python, Django                     | pypi.org → Account settings → **API tokens**. A brand-new project needs an _entire account_ token for its first upload; afterwards create a project-scoped token and replace it. TestPyPI has its own account and token                                                                                     |
| `NUGET_API_KEY`                                                     | .NET, Unity                        | nuget.org → profile → **API Keys** → Create: scope _Push_, glob pattern for your package ids (e.g. `Acme.*`). Keys expire – note the date                                                                                                                                                                   |
| `MAVEN_CENTRAL_USERNAME` / `MAVEN_CENTRAL_PASSWORD`                 | Maven, Gradle                      | central.sonatype.com → account → **Generate User Token** (shows a username _and_ a password). Your namespace must be verified first                                                                                                                                                                         |
| `GPG_PRIVATE_KEY` / `GPG_PASSPHRASE`                                | Maven                              | `gpg --armor --export-secret-keys <KEYID>` → paste the whole block (including the BEGIN/END lines). Publish the public key to a keyserver: `gpg --keyserver keyserver.ubuntu.com --send-keys <KEYID>`                                                                                                       |
| `SIGNING_KEY` / `SIGNING_KEY_ID` / `SIGNING_PASSWORD`               | Gradle                             | Same GPG key as above: `SIGNING_KEY` = armored private key, `SIGNING_PASSWORD` = its passphrase, `SIGNING_KEY_ID` = the short key id (optional)                                                                                                                                                             |
| `GRADLE_PUBLISH_KEY` / `GRADLE_PUBLISH_SECRET`                      | Gradle (Plugin Portal)             | plugins.gradle.org → your account → **API Keys**                                                                                                                                                                                                                                                            |
| `CARGO_REGISTRY_TOKEN`                                              | Rust                               | crates.io → Account Settings → **API Tokens** → New Token with the _publish-new_ / _publish-update_ scopes (restrict by crate name if you can)                                                                                                                                                              |
| `PACKAGIST_USERNAME` / `PACKAGIST_API_TOKEN`                        | PHP, Laravel                       | packagist.org → profile → **Show API Token**                                                                                                                                                                                                                                                                |
| `RUBYGEMS_API_KEY`                                                  | Ruby                               | rubygems.org → Profile → **API keys** → New, scope _Push rubygem_                                                                                                                                                                                                                                           |
| `COCOAPODS_TRUNK_TOKEN`                                             | Swift                              | `pod trunk register you@example.com "Your Name"`; the token is written to `~/.netrc` (field `password` of `machine trunk.cocoapods.org`)                                                                                                                                                                    |
| `SVN_USERNAME` / `SVN_PASSWORD`                                     | WordPress                          | Your WordPress.org account that is a committer of the plugin (use the dedicated SVN password if your account has one)                                                                                                                                                                                       |
| `UNITY_LICENSE` · `UNITY_EMAIL` · `UNITY_PASSWORD` · `UNITY_SERIAL` | Unity (tests)                      | See [game.ci → GitHub → Activation](https://game.ci/docs/github/activation)                                                                                                                                                                                                                                 |
| `CSC_LINK` / `CSC_KEY_PASSWORD`                                     | Electron                           | Signing certificate (`.p12`/`.pfx`) as base64 or URL, and its password. `base64 -i cert.p12 \| pbcopy` on macOS                                                                                                                                                                                             |
| `WIN_CSC_LINK` / `WIN_CSC_KEY_PASSWORD`                             | Electron                           | Separate Windows certificate (otherwise `CSC_LINK` is used)                                                                                                                                                                                                                                                 |
| `APPLE_ID` · `APPLE_APP_SPECIFIC_PASSWORD` · `APPLE_TEAM_ID`        | Electron                           | macOS notarization: Apple ID, an app-specific password from appleid.apple.com, and your team id                                                                                                                                                                                                             |

---

<a id="publishing-workflows"></a>

## Publishing workflows

One section per ecosystem: what to set up once, which secrets to add, a ready-to-copy caller workflow, and the inputs.

<a id="flutter"></a>

### Flutter

**Workflow:** `publish-flutter.yml` · **Publishes to:** [pub.dev](https://pub.dev) · **Auth:** GitHub OIDC (no secret)

**One-time setup** (pub.dev must already know the package, so publish the very first version by hand with `dart pub publish`):

1. pub.dev → your package → **Admin** → _Automated publishing_ → enable **GitHub Actions**.
2. Repository: `OWNER/REPO` of **your package repository** (not this one). Tag pattern: `v{{version}}`.

**Secrets:** none.

#### Caller workflow

```yaml
name: Publish to pub.dev
on:
  push:
    tags: ["v[0-9]+.[0-9]+.[0-9]+*"] # must match the tag pattern configured on pub.dev

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

#### Inputs

Plus the [common inputs](#common-inputs).

| Input             | Type    | Default         | Description                                                                       |
| ----------------- | ------- | --------------- | --------------------------------------------------------------------------------- |
| `flutter_version` | string  | _(empty)_       | Flutter SDK version, e.g. 3.38.1 (empty = latest of the channel)                  |
| `flutter_channel` | string  | `stable`        | Flutter channel                                                                   |
| `dart_only`       | boolean | `false`         | Pure Dart package: use the Dart SDK (dart analyze / dart test) instead of Flutter |
| `runner`          | string  | `ubuntu-latest` | Runner label. Use macos-latest if the package needs Xcode tooling                 |
| `check_format`    | boolean | `false`         | Fail if `dart format` would change lib/ or test/                                  |
| `run_analyze`     | boolean | `true`          | Run static analysis                                                               |
| `run_tests`       | boolean | `true`          | Run tests (skipped automatically when there is no test/ directory)                |
| `dry_run`         | boolean | `false`         | Run everything except the final upload (uses `pub publish --dry-run`)             |

#### Notes

- The package version must equal the tag (`version: 1.2.3` ↔ `v1.2.3`; build suffixes such as `1.2.3+4` must be in the tag too).
- `dart_only: true` switches to `dart analyze` / `dart test` for pure Dart packages and skips the Flutter SDK install.
- Use `runner: macos-latest` for plugins whose checks need Xcode. macOS minutes cost 10× Linux minutes.

---

<a id="npm"></a>

### npm

**Workflow:** `publish-npm.yml` · **Publishes to:** npmjs.com, or any npm registry (e.g. GitHub Packages) · **Auth:** `NPM_TOKEN`

#### Secrets

| Secret      | Required                | Notes                                           |
| ----------- | ----------------------- | ----------------------------------------------- |
| `NPM_TOKEN` | yes (not for `dry_run`) | See the [secrets reference](#secrets-reference) |

#### Caller workflow

```yaml
name: Publish to npm
on:
  push:
    tags: ["v*.*.*"]

jobs:
  publish:
    permissions:
      contents: read
      id-token: write # required by GitHub when provenance is enabled
    uses: KMM-ZONE/open-flows/.github/workflows/publish-npm.yml@v1
    with:
      node_version: "24"
      package_manager: pnpm # npm | yarn | pnpm
      provenance: true # public repositories only
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

#### Inputs

Plus the [common inputs](#common-inputs).

| Input               | Type    | Default                      | Description                                                                                |
| ------------------- | ------- | ---------------------------- | ------------------------------------------------------------------------------------------ |
| `node_version`      | string  | `24`                         | Node.js version                                                                            |
| `package_manager`   | string  | `npm`                        | Package manager used for installing dependencies: npm \| yarn \| pnpm                      |
| `install_directory` | string  | `.`                          | Directory where dependencies are installed (workspace root for monorepos)                  |
| `registry_url`      | string  | `https://registry.npmjs.org` | Registry URL                                                                               |
| `access`            | string  | `public`                     | Package access: public \| restricted                                                       |
| `dist_tag`          | string  | _(empty)_                    | npm dist-tag. Empty = latest, or the pre-release id (1.0.0-beta.1 -> beta, otherwise next) |
| `provenance`        | boolean | `false`                      | Publish with provenance (public repos only; needs id-token: write in the caller)           |
| `cache`             | boolean | `true`                       | Cache the package manager store (needs a lock file)                                        |
| `run_tests`         | boolean | `true`                       | Run `npm run test` (skipped when the script does not exist)                                |
| `run_build`         | boolean | `true`                       | Run `npm run build` (skipped when the script does not exist)                               |
| `publish_command`   | string  | _(empty)_                    | Custom publish command (e.g. 'pnpm publish --no-git-checks'). Empty = npm publish          |
| `dry_run`           | boolean | `false`                      | Run everything except the final upload (uses `npm publish --dry-run`)                      |

#### Notes

- `npm run test` and `npm run build` run only if those scripts exist (`--if-present`).
- Pre-release versions get a matching dist-tag automatically (`1.0.0-beta.2` → `beta`, `2.0.0-0` → `next`), because npm refuses to publish a pre-release as `latest`.
- **Monorepo:** install at the workspace root and publish one package:
  `install_directory: "."`, `working_directory: packages/ui`, `tag_prefix: "ui-v"`.
- **GitHub Packages:** `registry_url: https://npm.pkg.github.com` and pass a personal access token with `write:packages` as `NPM_TOKEN`.
- pnpm workspaces that use the `workspace:` protocol should set `publish_command: "pnpm publish --no-git-checks"`.

---

<a id="react-native"></a>

### React Native

**Workflow:** `publish-react-native.yml` · **Publishes to:** npm · **Auth:** `NPM_TOKEN`

Same as [npm](#npm), tuned for libraries created with `create-react-native-library` / `react-native-builder-bob`: Yarn by default, plus `typecheck` and `lint` steps before the tests and the build.

**Secrets:** `NPM_TOKEN` (see the [secrets reference](#secrets-reference)).

#### Caller workflow

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

#### Inputs

Plus the [common inputs](#common-inputs).

| Input               | Type    | Default                      | Description                                                                                |
| ------------------- | ------- | ---------------------------- | ------------------------------------------------------------------------------------------ |
| `node_version`      | string  | `24`                         | Node.js version                                                                            |
| `package_manager`   | string  | `yarn`                       | Package manager used for installing dependencies: npm \| yarn \| pnpm                      |
| `install_directory` | string  | `.`                          | Directory where dependencies are installed (workspace root for monorepos)                  |
| `registry_url`      | string  | `https://registry.npmjs.org` | Registry URL                                                                               |
| `access`            | string  | `public`                     | Package access: public \| restricted                                                       |
| `dist_tag`          | string  | _(empty)_                    | npm dist-tag. Empty = latest, or the pre-release id (1.0.0-beta.1 -> beta, otherwise next) |
| `provenance`        | boolean | `false`                      | Publish with provenance (public repos only; needs id-token: write in the caller)           |
| `cache`             | boolean | `true`                       | Cache the package manager store (needs a lock file)                                        |
| `run_typecheck`     | boolean | `true`                       | Run `npm run typecheck` (skipped when the script does not exist)                           |
| `run_lint`          | boolean | `true`                       | Run `npm run lint` (skipped when the script does not exist)                                |
| `run_tests`         | boolean | `true`                       | Run `npm run test` (skipped when the script does not exist)                                |
| `run_build`         | boolean | `true`                       | Run `npm run build` (skipped when the script does not exist)                               |
| `publish_command`   | string  | _(empty)_                    | Custom publish command (e.g. 'pnpm publish --no-git-checks'). Empty = npm publish          |
| `dry_run`           | boolean | `false`                      | Run everything except the final upload (uses `npm publish --dry-run`)                      |

#### Notes

- `typecheck`, `lint`, `test` and `build` scripts are run only if they exist in `package.json`.
- `bob build` normally runs from the `prepare` script, so installing dependencies already builds the library; the explicit `build` step is a no-op if you have no `build` script.
- Monorepo with an `example/` app: set `working_directory` to the library folder and keep `install_directory: "."`.

---

<a id="electron"></a>

### Electron

**Workflow:** `publish-electron.yml` · **Publishes to:** npm and/or desktop installers attached to the GitHub Release · **Auth:** `NPM_TOKEN`, optional code-signing secrets

Three independent parts, switch each on or off:

1. **meta** – reads the version and checks the tag (always runs).
2. **npm** (`publish_npm: true`) – installs, tests, builds and publishes the package.
3. **installers** (`build_installers: true`) – builds with `electron-builder` on macOS, Windows and Linux and uploads the installers to the release of the tag.

#### Secrets

| Secret                                                     | Required                     | Notes                                                                              |
| ---------------------------------------------------------- | ---------------------------- | ---------------------------------------------------------------------------------- |
| `NPM_TOKEN`                                                | when `publish_npm` is `true` |                                                                                    |
| `CSC_LINK`, `CSC_KEY_PASSWORD`                             | no                           | Signing certificate and password (macOS, and Windows unless `WIN_CSC_LINK` is set) |
| `WIN_CSC_LINK`, `WIN_CSC_KEY_PASSWORD`                     | no                           | Windows certificate                                                                |
| `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID` | no                           | macOS notarization                                                                 |

Without the signing secrets the installers are still built – unsigned.

#### Caller workflow

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

#### Inputs

Plus the [common inputs](#common-inputs).

| Input               | Type    | Default                                             | Description                                                                                |
| ------------------- | ------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| `node_version`      | string  | `24`                                                | Node.js version                                                                            |
| `package_manager`   | string  | `npm`                                               | npm \| yarn \| pnpm                                                                        |
| `install_directory` | string  | `.`                                                 | Directory where dependencies are installed (workspace root for monorepos)                  |
| `run_tests`         | boolean | `true`                                              | Run `npm run test` (skipped when the script does not exist)                                |
| `run_build`         | boolean | `true`                                              | Run `npm run build` (skipped when the script does not exist)                               |
| `publish_npm`       | boolean | `true`                                              | Publish the package to npm                                                                 |
| `registry_url`      | string  | `https://registry.npmjs.org`                        | npm registry URL                                                                           |
| `access`            | string  | `public`                                            | npm access: public \| restricted                                                           |
| `dist_tag`          | string  | _(empty)_                                           | npm dist-tag. Empty = latest, or the pre-release id (1.0.0-beta.1 -> beta, otherwise next) |
| `provenance`        | boolean | `false`                                             | Publish to npm with provenance (public repos only)                                         |
| `build_installers`  | boolean | `false`                                             | Build desktop installers with electron-builder and attach them to the GitHub Release       |
| `installer_os`      | string  | `["macos-latest","windows-latest","ubuntu-latest"]` | JSON array of runner labels to build installers on                                         |
| `installer_command` | string  | `npx electron-builder --publish never`              | Command that produces the installers (must NOT publish by itself)                          |
| `dist_directory`    | string  | `dist`                                              | Directory (relative to working_directory) where electron-builder writes installers         |
| `dry_run`           | boolean | `false`                                             | Build everything but do not upload to npm or the GitHub Release                            |

#### Notes

- `installer_command` must **not** publish by itself – use `--publish never` (the default does). The workflow uploads the files so that every OS attaches to the same release.
- `published` is `'true'` only when the npm upload happened; installers are reported in the release itself.
- Windows runners need Git Bash (preinstalled on GitHub-hosted runners).

---

<a id="python"></a>

### Python

**Workflow:** `publish-python.yml` · **Publishes to:** PyPI (or TestPyPI / a private index) · **Auth:** `PYPI_API_TOKEN`

#### Secrets

| Secret           | Required                | Notes                                                                                          |
| ---------------- | ----------------------- | ---------------------------------------------------------------------------------------------- |
| `PYPI_API_TOKEN` | yes (not for `dry_run`) | First upload of a new project needs an account-wide token; then switch to a project-scoped one |

#### Caller workflow

```yaml
name: Publish to PyPI
on:
  push:
    tags: ["v*.*.*"]

jobs:
  publish:
    permissions:
      contents: read
    uses: KMM-ZONE/open-flows/.github/workflows/publish-python.yml@v1
    with:
      python_version: "3.13"
      install_command: 'python -m pip install -e ".[test]"'
      test_command: pytest
    secrets:
      PYPI_API_TOKEN: ${{ secrets.PYPI_API_TOKEN }}
```

Rehearse on **TestPyPI** first (create a separate token at test.pypi.org and store it as `TEST_PYPI_API_TOKEN`):

```yaml
with:
  repository_url: https://test.pypi.org/legacy/
secrets:
  PYPI_API_TOKEN: ${{ secrets.TEST_PYPI_API_TOKEN }}
```

#### Inputs

Plus the [common inputs](#common-inputs).

| Input             | Type    | Default                              | Description                                                                        |
| ----------------- | ------- | ------------------------------------ | ---------------------------------------------------------------------------------- |
| `python_version`  | string  | `3.13`                               | Python version                                                                     |
| `install_command` | string  | `python -m pip install -e ".[test]"` | Installs the project plus its test dependencies (used only when run_tests is true) |
| `run_tests`       | boolean | `true`                               | Run the test command before building                                               |
| `test_command`    | string  | `pytest`                             | Test command                                                                       |
| `repository_url`  | string  | `https://upload.pypi.org/legacy/`    | Upload URL (use `https://test.pypi.org/legacy/` for TestPyPI)                      |
| `dry_run`         | boolean | `false`                              | Build and run `twine check`, but do not upload                                     |

#### Notes

- Name and version are read **from the built distribution**, so static versions, `setuptools_scm`, `hatch-vcs` and `dynamic = ["version"]` all work (the checkout fetches tags for that reason).
- The tag must equal the _normalised_ PEP 440 version: version `1.4.2rc1` needs tag `v1.4.2rc1`, not `v1.4.2-rc.1`.
- Tests run only if `run_tests` is true; they need `pytest` (or your `test_command`) to be installed by `install_command`.
- Wheels and the sdist are checked with `twine check` before the upload.

---

<a id="django"></a>

### Django

**Workflow:** `publish-django.yml` · **Publishes to:** PyPI · **Auth:** `PYPI_API_TOKEN`

For reusable Django apps: tests run against a **Python × Django matrix**, and only if every combination passes is the package built and uploaded (same publish steps as [Python](#python)).

**Secrets:** `PYPI_API_TOKEN` (see the [secrets reference](#secrets-reference)).

#### Caller workflow

```yaml
name: Publish Django app
on:
  push:
    tags: ["v*.*.*"]

jobs:
  publish:
    permissions:
      contents: read
    uses: KMM-ZONE/open-flows/.github/workflows/publish-django.yml@v1
    with:
      settings_module: tests.settings
      matrix: >-
        [{"python":"3.12","django":"5.2"},
         {"python":"3.13","django":"5.2"},
         {"python":"3.13","django":"6.0"}]
    secrets:
      PYPI_API_TOKEN: ${{ secrets.PYPI_API_TOKEN }}
```

#### Inputs

Plus the [common inputs](#common-inputs).

| Input             | Type    | Default                                                                                                | Description                                                                                     |
| ----------------- | ------- | ------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------- |
| `python_version`  | string  | `3.13`                                                                                                 | Python version used for the build/publish job                                                   |
| `matrix`          | string  | `[{"python":"3.12","django":"5.2"},{"python":"3.13","django":"5.2"},{"python":"3.13","django":"6.0"}]` | JSON array of {"python","django"} pairs to test against                                         |
| `settings_module` | string  | _(empty)_                                                                                              | DJANGO_SETTINGS_MODULE used by the tests (e.g. tests.settings). Empty = rely on your own config |
| `install_command` | string  | `python -m pip install -e ".[test]"`                                                                   | Installs the project plus its test dependencies (used only when run_tests is true)              |
| `run_tests`       | boolean | `true`                                                                                                 | Run the Python x Django test matrix before building                                             |
| `test_command`    | string  | `python -m django test`                                                                                | Test command (e.g. 'pytest' or 'python runtests.py')                                            |
| `repository_url`  | string  | `https://upload.pypi.org/legacy/`                                                                      | Upload URL (use `https://test.pypi.org/legacy/` for TestPyPI)                                   |
| `dry_run`         | boolean | `false`                                                                                                | Build and run `twine check`, but do not upload                                                  |

#### Notes

- Each matrix entry installs your project (`install_command`), then pins `Django==<django>.*`, then runs `test_command` with `DJANGO_SETTINGS_MODULE` set from `settings_module`.
- Using pytest? Set `test_command: pytest` (and configure `DJANGO_SETTINGS_MODULE` in `pytest.ini`, or leave `settings_module` set).
- Check which Python versions each Django release supports before adding rows to the matrix.

---

<a id="dotnet"></a>

### .NET

**Workflow:** `publish-dotnet.yml` · **Publishes to:** NuGet (nuget.org or another feed) · **Auth:** `NUGET_API_KEY`

#### Secrets

| Secret          | Required                | Notes                                                  |
| --------------- | ----------------------- | ------------------------------------------------------ |
| `NUGET_API_KEY` | yes (not for `dry_run`) | Scope _Push_; glob pattern must cover your package ids |

#### Caller workflow

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
      version_from_tag: true # tag v1.2.3 -> package version 1.2.3
    secrets:
      NUGET_API_KEY: ${{ secrets.NUGET_API_KEY }}
```

#### Inputs

Plus the [common inputs](#common-inputs).

| Input              | Type    | Default                               | Description                                                                                            |
| ------------------ | ------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `dotnet_version`   | string  | `10.0.x`                              | SDK version(s), one per line, e.g. '8.0.x' or '9.0.x' + newline + '10.0.x'                             |
| `project`          | string  | _(empty)_                             | Solution or project to restore/build/test/pack (empty = the one in working_directory)                  |
| `configuration`    | string  | `Release`                             | Build configuration                                                                                    |
| `version_from_tag` | boolean | `false`                               | On tag pushes, build and pack with -p:Version=`<tag without prefix>` (no version in the csproj needed) |
| `run_tests`        | boolean | `true`                                | Run `dotnet test`                                                                                      |
| `test_args`        | string  | _(empty)_                             | Extra arguments for `dotnet test`                                                                      |
| `nuget_source`     | string  | `https://api.nuget.org/v3/index.json` | NuGet push source URL                                                                                  |
| `dry_run`          | boolean | `false`                               | Build, test and pack, but do not push                                                                  |

#### Notes

- With `version_from_tag: true` the version is passed as `-p:Version=…`, so you do not have to edit the `.csproj` for each release. Otherwise the version comes from the project (`<Version>`, MinVer, Nerdbank.GitVersioning – the checkout fetches tags).
- The workflow reads id and version of **every** `.nupkg` and, with `verify_tag`, fails if the tag does not match them all. Set `verify_tag: false` for solutions whose packages version independently.
- Re-runs are safe: `dotnet nuget push --skip-duplicate` leaves existing versions untouched (there is no separate `skip_if_published` input).
- The project must be packable (`<IsPackable>true</IsPackable>`). When you pack a **solution**, mark test and sample projects `<IsPackable>false</IsPackable>`, or point `project` at the specific `.csproj`.
- A matching `.snupkg` symbol package is pushed together with the `.nupkg`.

---

<a id="maven"></a>

### Maven

**Workflow:** `publish-maven.yml` · **Publishes to:** Maven Central via the Central Publisher Portal · **Auth:** Portal user token + GPG key

#### One-time setup

1. Create an account at [central.sonatype.com](https://central.sonatype.com) and **verify your namespace** (e.g. `io.github.yourname` or your own domain).
2. Generate a **user token** (gives `MAVEN_CENTRAL_USERNAME` and `MAVEN_CENTRAL_PASSWORD`).
3. Create a GPG key, export the private key into `GPG_PRIVATE_KEY`, and publish the public key to a keyserver (commands in the [secrets reference](#secrets-reference)).
4. Add a **`release` profile** to your `pom.xml` (below). Central requires sources, javadoc, signatures and complete POM metadata (`name`, `description`, `url`, `licenses`, `developers`, `scm`).

```xml
<profiles>
  <profile>
    <id>release</id>
    <build>
      <plugins>
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-source-plugin</artifactId>
          <version>3.3.1</version>
          <executions>
            <execution><id>attach-sources</id><goals><goal>jar-no-fork</goal></goals></execution>
          </executions>
        </plugin>
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-javadoc-plugin</artifactId>
          <version>3.11.2</version>
          <executions>
            <execution><id>attach-javadocs</id><goals><goal>jar</goal></goals></execution>
          </executions>
        </plugin>
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-gpg-plugin</artifactId>
          <version>3.2.8</version>
          <executions>
            <execution>
              <id>sign-artifacts</id>
              <phase>verify</phase>
              <goals><goal>sign</goal></goals>
              <configuration>
                <gpgArguments>
                  <arg>--pinentry-mode</arg>
                  <arg>loopback</arg>
                </gpgArguments>
              </configuration>
            </execution>
          </executions>
        </plugin>
        <plugin>
          <groupId>org.sonatype.central</groupId>
          <artifactId>central-publishing-maven-plugin</artifactId>
          <version>0.11.0</version>
          <extensions>true</extensions>
          <configuration>
            <publishingServerId>central</publishingServerId>
            <autoPublish>true</autoPublish>
            <waitUntil>published</waitUntil>
          </configuration>
        </plugin>
      </plugins>
    </build>
  </profile>
</profiles>
```

(Plugin versions are what was current when this was written – use the latest.) The `publishingServerId` must equal the `server_id` input (default `central`).

#### Secrets

| Secret                                             | Required                |
| -------------------------------------------------- | ----------------------- |
| `MAVEN_CENTRAL_USERNAME`, `MAVEN_CENTRAL_PASSWORD` | yes (not for `dry_run`) |
| `GPG_PRIVATE_KEY`, `GPG_PASSPHRASE`                | yes (not for `dry_run`) |

#### Caller workflow

```yaml
name: Publish to Maven Central
on:
  push:
    tags: ["v*.*.*"]

jobs:
  publish:
    permissions:
      contents: read
    uses: KMM-ZONE/open-flows/.github/workflows/publish-maven.yml@v1
    with:
      java_version: "17"
    secrets:
      MAVEN_CENTRAL_USERNAME: ${{ secrets.MAVEN_CENTRAL_USERNAME }}
      MAVEN_CENTRAL_PASSWORD: ${{ secrets.MAVEN_CENTRAL_PASSWORD }}
      GPG_PRIVATE_KEY: ${{ secrets.GPG_PRIVATE_KEY }}
      GPG_PASSPHRASE: ${{ secrets.GPG_PASSPHRASE }}
```

#### Inputs

Plus the [common inputs](#common-inputs).

| Input               | Type    | Default   | Description                                                                        |
| ------------------- | ------- | --------- | ---------------------------------------------------------------------------------- |
| `java_version`      | string  | `17`      | JDK version                                                                        |
| `java_distribution` | string  | `temurin` | JDK distribution (temurin, zulu, corretto, ...)                                    |
| `profiles`          | string  | `release` | Maven profile(s) activated for the deploy, comma separated (empty = none)          |
| `server_id`         | string  | `central` | `<server><id>` in settings.xml that receives the credentials (must match your pom) |
| `run_tests`         | boolean | `true`    | Run `mvn verify` before deploying (the deploy itself then skips tests)             |
| `maven_args`        | string  | _(empty)_ | Extra arguments appended to the deploy command                                     |
| `dry_run`           | boolean | `false`   | Run `mvn verify` with signing disabled, but do not deploy                          |

#### Notes

- Group, artifact and version are read with `mvn help:evaluate`; the version must equal the tag and must not be a `-SNAPSHOT`.
- `skip_if_published` checks `repo1.maven.org`. Central sync can lag a few minutes behind a successful deploy.
- Maven Central versions are immutable – a bad release needs a new version number.

---

<a id="gradle"></a>

### Gradle

**Workflow:** `publish-gradle.yml` · **Publishes to:** Maven Central (default) or the Gradle Plugin Portal · **Auth:** Portal token + signing key, or Plugin Portal key

Works for Java, Kotlin, Android and Kotlin Multiplatform libraries. The default task is `publishAndReleaseToMavenCentral` from the [`com.vanniktech.maven.publish`](https://vanniktech.github.io/gradle-maven-publish-plugin/) plugin:

```kotlin
// build.gradle.kts
plugins {
    id("com.vanniktech.maven.publish") version "<latest>"
}

mavenPublishing {
    publishToMavenCentral()      // check the plugin docs for the exact DSL of your plugin version
    signAllPublications()
    coordinates("com.example", "my-lib", version.toString())
    pom { /* name, description, url, licenses, developers, scm */ }
}
```

```properties
# gradle.properties – the version the tag must match
version=1.2.3
```

#### Secrets

| Secret                                                                                | Required                                               |
| ------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| `MAVEN_CENTRAL_USERNAME`, `MAVEN_CENTRAL_PASSWORD`, `SIGNING_KEY`, `SIGNING_PASSWORD` | for Maven Central                                      |
| `SIGNING_KEY_ID`                                                                      | optional                                               |
| `GRADLE_PUBLISH_KEY`, `GRADLE_PUBLISH_SECRET`                                         | for the Plugin Portal (`publish_task: publishPlugins`) |

They are handed to Gradle as `ORG_GRADLE_PROJECT_mavenCentralUsername`, `…mavenCentralPassword`, `…signingInMemoryKey`, `…signingInMemoryKeyId`, `…signingInMemoryKeyPassword`, plus `GRADLE_PUBLISH_KEY` / `GRADLE_PUBLISH_SECRET`.

#### Caller workflow

Maven Central:

```yaml
name: Publish with Gradle
on:
  push:
    tags: ["v*.*.*"]

jobs:
  publish:
    permissions:
      contents: read
    uses: KMM-ZONE/open-flows/.github/workflows/publish-gradle.yml@v1
    with:
      java_version: "17"
      test_task: check
    secrets:
      MAVEN_CENTRAL_USERNAME: ${{ secrets.MAVEN_CENTRAL_USERNAME }}
      MAVEN_CENTRAL_PASSWORD: ${{ secrets.MAVEN_CENTRAL_PASSWORD }}
      SIGNING_KEY: ${{ secrets.SIGNING_KEY }}
      SIGNING_PASSWORD: ${{ secrets.SIGNING_PASSWORD }}
```

Gradle Plugin Portal:

```yaml
with:
  publish_task: publishPlugins
secrets:
  GRADLE_PUBLISH_KEY: ${{ secrets.GRADLE_PUBLISH_KEY }}
  GRADLE_PUBLISH_SECRET: ${{ secrets.GRADLE_PUBLISH_SECRET }}
```

#### Inputs

Plus the [common inputs](#common-inputs); this workflow has no `skip_if_published`.

| Input               | Type    | Default                           | Description                                                                                                        |
| ------------------- | ------- | --------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `runner`            | string  | `ubuntu-latest`                   | Runner label. Kotlin Multiplatform libraries with Apple targets need macos-latest                                  |
| `java_version`      | string  | `17`                              | JDK version                                                                                                        |
| `java_distribution` | string  | `temurin`                         | JDK distribution                                                                                                   |
| `project_path`      | string  | _(empty)_                         | Gradle project path used to read the version, e.g. ':library' (empty = root project)                               |
| `run_tests`         | boolean | `true`                            | Run the test task before publishing                                                                                |
| `test_task`         | string  | `check`                           | Gradle task that builds and tests                                                                                  |
| `publish_task`      | string  | `publishAndReleaseToMavenCentral` | Gradle task that publishes (publishAndReleaseToMavenCentral \| publishToMavenCentral \| publishPlugins \| publish) |
| `dry_run_task`      | string  | `publishToMavenLocal`             | Task run instead of publish_task when dry_run is true                                                              |
| `gradle_args`       | string  | _(empty)_                         | Extra arguments for the publish command                                                                            |
| `dry_run`           | boolean | `false`                           | Run dry_run_task instead of publishing                                                                             |

#### Notes

- The version is read with `./gradlew properties`; a project whose version is `unspecified` fails with a clear message. Use `project_path: ":library"` to read it from a subproject.
- Kotlin Multiplatform with Apple targets needs `runner: macos-latest`.
- `dry_run` runs `dry_run_task` (default `publishToMavenLocal`) instead of publishing.

---

<a id="rust"></a>

### Rust

**Workflow:** `publish-cargo.yml` · **Publishes to:** [crates.io](https://crates.io) · **Auth:** `CARGO_REGISTRY_TOKEN`

#### Secrets

| Secret                 | Required                |
| ---------------------- | ----------------------- |
| `CARGO_REGISTRY_TOKEN` | yes (not for `dry_run`) |

#### Caller workflow

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

#### Inputs

Plus the [common inputs](#common-inputs).

| Input         | Type    | Default   | Description                                                                                 |
| ------------- | ------- | --------- | ------------------------------------------------------------------------------------------- |
| `toolchain`   | string  | `stable`  | Rust toolchain (stable, beta, nightly, 1.85, ...)                                           |
| `package`     | string  | _(empty)_ | Crate to publish from a workspace (cargo -p). Empty = the only/first package                |
| `run_tests`   | boolean | `true`    | Run `cargo test`                                                                            |
| `test_args`   | string  | _(empty)_ | Extra arguments for `cargo test`, e.g. --all-features                                       |
| `run_clippy`  | boolean | `false`   | Run `cargo clippy -- -D warnings`                                                           |
| `allow_dirty` | boolean | `false`   | Pass --allow-dirty to cargo publish (needed when Cargo.lock is generated and not committed) |
| `dry_run`     | boolean | `false`   | Run `cargo publish --dry-run` instead of publishing                                         |

#### Notes

- Name and version come from `cargo metadata`; `package` selects a crate in a workspace.
- Cargo refuses to publish from a dirty working tree. If `Cargo.lock` is generated during the run and not committed, set `allow_dirty: true`.
- `crates.io` versions cannot be overwritten, only yanked.
- A crate needs `description` and `license` (or `license-file`) in `Cargo.toml`.

---

<a id="go"></a>

### Go

**Workflow:** `publish-go.yml` · **Publishes to:** the Go module ecosystem – **the git tag is the release** · **Secrets:** none

There is nothing to upload: `go get` resolves versions from your repository's tags through `proxy.golang.org`. This workflow therefore:

1. checks the tag is `vMAJOR.MINOR.PATCH[-pre]`, and – for v2 and above – that your module path ends in `/vN`
2. runs `go vet`, `go build` and `go test`
3. asks `proxy.golang.org` for the new version so `go get` and pkg.go.dev see it immediately
4. creates the GitHub Release with generated notes (skipped if one already exists)

#### Caller workflow

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

#### Inputs

Plus the [common inputs](#common-inputs); `verify_tag` and `skip_if_published` do not apply – the tag _is_ the version.

| Input            | Type    | Default   | Description                                                                                          |
| ---------------- | ------- | --------- | ---------------------------------------------------------------------------------------------------- |
| `go_version`     | string  | _(empty)_ | Go version (empty = the version in go.mod)                                                           |
| `tag`            | string  | _(empty)_ | Existing tag to release (for workflow_dispatch). Empty = the tag that triggered the run              |
| `tag_prefix`     | string  | _(empty)_ | Text before the 'v' in the tag. Empty for v1.2.3; 'sub/dir/' for sub-module tags like sub/dir/v1.2.3 |
| `run_vet`        | boolean | `true`    | Run `go vet`                                                                                         |
| `run_tests`      | boolean | `true`    | Run `go test`                                                                                        |
| `test_args`      | string  | `./...`   | Arguments for `go test`                                                                              |
| `warm_proxy`     | boolean | `true`    | Request the new version from proxy.golang.org so it is indexed right away                            |
| `github_release` | boolean | `true`    | Create a GitHub Release with generated notes (skipped when it already exists)                        |
| `dry_run`        | boolean | `false`   | Validate, vet and test only                                                                          |

#### Notes

- `tag_prefix` here is the text **before the `v`** (empty by default), because Go requires the `v`.
- Releasing an existing tag by hand: run the workflow with `workflow_dispatch` and pass `tag: v1.2.3`.
- Private repositories cannot be fetched by the public proxy – set `warm_proxy: false`.
- The `published` output is `'true'` when the proxy was warmed or the release created.

---

<a id="php"></a>

### PHP / Composer

**Workflow:** `publish-composer.yml` · **Publishes to:** [Packagist](https://packagist.org) · **Auth:** `PACKAGIST_USERNAME` + `PACKAGIST_API_TOKEN` _(optional)_

Packagist builds versions from your **git tags**; `composer.json` must **not** contain a `version` key. This workflow validates `composer.json` (`--strict`), installs, runs tests, checks the tag is a semantic version and tells Packagist to re-crawl the repository.

**One-time setup:** submit the repository once at packagist.org → _Submit_. Packagist can also update by itself through its GitHub hook; if that is enabled you can omit both secrets – the workflow then only validates and tests.

#### Secrets

| Secret                                      | Required                                                              |
| ------------------------------------------- | --------------------------------------------------------------------- |
| `PACKAGIST_USERNAME`, `PACKAGIST_API_TOKEN` | no – without them the Packagist notification is skipped with a notice |

#### Caller workflow

```yaml
name: Publish to Packagist
on:
  push:
    tags: ["v*.*.*"]

jobs:
  publish:
    permissions:
      contents: read
    uses: KMM-ZONE/open-flows/.github/workflows/publish-composer.yml@v1
    with:
      php_version: "8.3"
      php_extensions: mbstring, intl
    secrets:
      PACKAGIST_USERNAME: ${{ secrets.PACKAGIST_USERNAME }}
      PACKAGIST_API_TOKEN: ${{ secrets.PACKAGIST_API_TOKEN }}
```

#### Inputs

Plus the [common inputs](#common-inputs); `skip_if_published` does not apply.

| Input            | Type    | Default                                        | Description                                                                                     |
| ---------------- | ------- | ---------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| `php_version`    | string  | `8.3`                                          | PHP version                                                                                     |
| `php_extensions` | string  | _(empty)_                                      | Comma separated PHP extensions for setup-php                                                    |
| `install_args`   | string  | `--prefer-dist --no-progress --no-interaction` | Arguments for `composer install`                                                                |
| `run_validate`   | boolean | `true`                                         | Run `composer validate --strict`                                                                |
| `run_tests`      | boolean | `true`                                         | Run the tests                                                                                   |
| `test_command`   | string  | _(empty)_                                      | Test command. Empty = `composer test` if defined, else vendor/bin/pest, else vendor/bin/phpunit |
| `package_url`    | string  | _(empty)_                                      | Repository URL registered on Packagist (empty = this repository on GitHub)                      |
| `dry_run`        | boolean | `false`                                        | Validate and test only; do not notify Packagist                                                 |

#### Notes

- With `test_command` empty the workflow runs `composer test` if your `composer.json` defines it, otherwise `vendor/bin/pest`, otherwise `vendor/bin/phpunit`.
- `published` is `'true'` only when Packagist accepted the update request.

---

<a id="laravel"></a>

### Laravel

**Workflow:** `publish-laravel.yml` · **Publishes to:** Packagist · **Auth:** `PACKAGIST_USERNAME` + `PACKAGIST_API_TOKEN` _(optional)_

Same publishing as [PHP / Composer](#php), preceded by a **PHP × Laravel test matrix** using [Orchestra Testbench](https://packages.tools/testbench). The publish job runs only when every matrix entry passes.

#### Caller workflow

```yaml
name: Publish Laravel package
on:
  push:
    tags: ["v*.*.*"]

jobs:
  publish:
    permissions:
      contents: read
    uses: KMM-ZONE/open-flows/.github/workflows/publish-laravel.yml@v1
    with:
      matrix: >-
        [{"php":"8.3","laravel":"11.*","testbench":"9.*"},
         {"php":"8.4","laravel":"12.*","testbench":"10.*"}]
    secrets:
      PACKAGIST_USERNAME: ${{ secrets.PACKAGIST_USERNAME }}
      PACKAGIST_API_TOKEN: ${{ secrets.PACKAGIST_API_TOKEN }}
```

#### Inputs

Plus the [common inputs](#common-inputs); `skip_if_published` and `working_directory` behave as in Composer.

| Input                 | Type    | Default                                                                                                | Description                                                                |
| --------------------- | ------- | ------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------- |
| `matrix`              | string  | `[{"php":"8.3","laravel":"11.*","testbench":"9.*"},{"php":"8.4","laravel":"12.*","testbench":"10.*"}]` | JSON array of {"php","laravel","testbench"} combinations to test           |
| `php_extensions`      | string  | `dom, curl, libxml, mbstring, zip, pcntl, pdo, sqlite, pdo_sqlite, bcmath, intl, gd, exif, iconv`      | Comma separated PHP extensions for setup-php                               |
| `publish_php_version` | string  | `8.4`                                                                                                  | PHP version for the publish job                                            |
| `run_tests`           | boolean | `true`                                                                                                 | Run the matrix tests                                                       |
| `test_command`        | string  | _(empty)_                                                                                              | Test command. Empty = vendor/bin/pest if present, else vendor/bin/phpunit  |
| `package_url`         | string  | _(empty)_                                                                                              | Repository URL registered on Packagist (empty = this repository on GitHub) |
| `dry_run`             | boolean | `false`                                                                                                | Validate and test only; do not notify Packagist                            |

#### Notes

- Testbench major versions follow Laravel's: Laravel 11 ↔ Testbench 9, Laravel 12 ↔ Testbench 10. Check the Testbench docs when you add a new Laravel major.
- Each entry runs `composer require laravel/framework:<x> orchestra/testbench:<y> --no-update` followed by `composer update --prefer-stable`.

---

<a id="ruby"></a>

### Ruby

**Workflow:** `publish-rubygems.yml` · **Publishes to:** [RubyGems.org](https://rubygems.org) · **Auth:** `RUBYGEMS_API_KEY`

#### Secrets

| Secret             | Required                                       |
| ------------------ | ---------------------------------------------- |
| `RUBYGEMS_API_KEY` | yes (not for `dry_run`) – scope _Push rubygem_ |

#### Caller workflow

```yaml
name: Publish gem
on:
  push:
    tags: ["v*.*.*"]

jobs:
  publish:
    permissions:
      contents: read
    uses: KMM-ZONE/open-flows/.github/workflows/publish-rubygems.yml@v1
    with:
      ruby_version: "3.4"
      test_command: bundle exec rake
    secrets:
      RUBYGEMS_API_KEY: ${{ secrets.RUBYGEMS_API_KEY }}
```

#### Inputs

Plus the [common inputs](#common-inputs).

| Input          | Type    | Default                | Description                                                            |
| -------------- | ------- | ---------------------- | ---------------------------------------------------------------------- |
| `ruby_version` | string  | `3.4`                  | Ruby version                                                           |
| `gemspec`      | string  | _(empty)_              | Gemspec file name (empty = the single \*.gemspec in working_directory) |
| `run_tests`    | boolean | `true`                 | Run the test command                                                   |
| `test_command` | string  | `bundle exec rake`     | Test command                                                           |
| `host`         | string  | `https://rubygems.org` | Gem host                                                               |
| `dry_run`      | boolean | `false`                | Build the gem but do not push it                                       |

#### Notes

- Name and version are read by loading the gemspec (`Gem::Specification.load`). The tag must equal `spec.version.to_s` – RubyGems writes pre-releases as `1.0.0.pre.beta`, so tag those as `v1.0.0.pre.beta`.
- A repository with several `.gemspec` files must set the `gemspec` input.
- If your gem sets `rubygems_mfa_required`, use an API key created with the matching MFA setting.

---

<a id="swift"></a>

### Swift / iOS

**Workflow:** `publish-swift.yml` · **Publishes to:** SwiftPM (**a git tag is the release**), optionally CocoaPods · **Secrets:** none for SwiftPM

Swift Package Manager resolves versions from git tags, so there is no upload. The workflow validates the tag, resolves, builds and tests on macOS, optionally pushes your podspec to CocoaPods trunk, and creates the GitHub Release.

#### Secrets

| Secret                  | Required                   |
| ----------------------- | -------------------------- |
| `COCOAPODS_TRUNK_TOKEN` | only when `podspec` is set |

#### Caller workflow

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

#### Inputs

Plus the [common inputs](#common-inputs); `verify_tag` and `skip_if_published` do not apply.

| Input                    | Type    | Default                                 | Description                                                                             |
| ------------------------ | ------- | --------------------------------------- | --------------------------------------------------------------------------------------- |
| `runner`                 | string  | `macos-15`                              | macOS runner label                                                                      |
| `xcode_version`          | string  | _(empty)_                               | Xcode version to select, e.g. 16.4 (empty = runner default)                             |
| `tag`                    | string  | _(empty)_                               | Existing tag to release (for workflow_dispatch). Empty = the tag that triggered the run |
| `tag_prefix`             | string  | _(empty)_                               | Optional text before the version in the tag (a leading v is always accepted)            |
| `run_tests`              | boolean | `true`                                  | Run `swift test`                                                                        |
| `build_args`             | string  | _(empty)_                               | Extra arguments for `swift build`                                                       |
| `test_args`              | string  | _(empty)_                               | Extra arguments for `swift test`                                                        |
| `xcodebuild_scheme`      | string  | _(empty)_                               | Also run `xcodebuild test` for this scheme (needed for iOS-only packages). Empty = skip |
| `xcodebuild_destination` | string  | `platform=iOS Simulator,name=iPhone 16` | Destination for xcodebuild test                                                         |
| `podspec`                | string  | _(empty)_                               | Path to a .podspec to push to CocoaPods trunk. Empty = SwiftPM only                     |
| `github_release`         | boolean | `true`                                  | Create a GitHub Release with generated notes (skipped when it already exists)           |
| `dry_run`                | boolean | `false`                                 | Build and test only (podspec is linted, nothing is pushed or released)                  |

#### Notes

- Tags may or may not start with `v`; the rest must be `MAJOR.MINOR.PATCH[-pre]`.
- With a `podspec`, its version must equal the tag version, or the run fails before pushing.
- macOS minutes cost 10× Linux minutes on GitHub-hosted runners. `xcode_version` must be installed on the chosen `runner` image.
- Releasing an existing tag by hand: `workflow_dispatch` with `tag: 1.2.3`.

---

<a id="unity"></a>

### Unity

**Workflow:** `publish-unity.yml` · **Publishes to:** npm and/or NuGet, plus a GitHub Release · **Auth:** `NPM_TOKEN`, `NUGET_API_KEY`

> **The Unity Asset Store has no upload API.** This workflow tests and packs your package and attaches the `.tgz` to the GitHub Release (and the workflow run); you upload it in the Asset Store **Publisher Portal** yourself. [OpenUPM](https://openupm.com) needs no CI at all – it builds from your git tags after you add the package to its list.

What it does: reads the UPM `package.json`, verifies the tag, optionally runs Unity tests with [game-ci](https://game.ci), runs `npm pack`, optionally publishes the tarball to an npm registry (Unity's scoped registries) and a NuGet package, and creates the release.

#### Secrets

| Secret                                                                         | Required                    |
| ------------------------------------------------------------------------------ | --------------------------- |
| `NPM_TOKEN`                                                                    | when `publish_npm: true`    |
| `NUGET_API_KEY`                                                                | when `publish_nuget: true`  |
| `UNITY_LICENSE`, `UNITY_EMAIL`, `UNITY_PASSWORD` (`UNITY_SERIAL` for Plus/Pro) | only when `run_tests: true` |

#### Caller workflow

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

#### Inputs

Plus the [common inputs](#common-inputs); `skip_if_published` and `working_directory` do not apply.

| Input            | Type    | Default                               | Description                                                                                |
| ---------------- | ------- | ------------------------------------- | ------------------------------------------------------------------------------------------ |
| `package_path`   | string  | `.`                                   | Folder containing the UPM package.json (e.g. . or Packages/com.company.pkg)                |
| `project_path`   | string  | `.`                                   | Unity project used to run tests (a test project that references the package)               |
| `unity_version`  | string  | `auto`                                | Unity version, or 'auto' to read ProjectSettings/ProjectVersion.txt                        |
| `lfs`            | boolean | `false`                               | Fetch Git LFS files                                                                        |
| `run_tests`      | boolean | `false`                               | Run Unity tests with game-ci (needs the UNITY\_\* secrets)                                 |
| `test_mode`      | string  | `all`                                 | editmode \| playmode \| all                                                                |
| `publish_npm`    | boolean | `false`                               | Publish the UPM package to an npm registry (scoped registry for the Unity Package Manager) |
| `npm_registry`   | string  | `https://registry.npmjs.org`          | npm registry URL                                                                           |
| `npm_access`     | string  | `public`                              | npm access: public \| restricted                                                           |
| `publish_nuget`  | boolean | `false`                               | Pack nuget_project and push it to NuGet                                                    |
| `nuget_project`  | string  | _(empty)_                             | Path to the .csproj to pack for NuGet (required when publish_nuget is true)                |
| `nuget_source`   | string  | `https://api.nuget.org/v3/index.json` | NuGet push source URL                                                                      |
| `dotnet_version` | string  | `9.0.x`                               | .NET SDK used for NuGet packing                                                            |
| `github_release` | boolean | `true`                                | Create a GitHub Release and attach the .tgz (and .nupkg)                                   |
| `dry_run`        | boolean | `false`                               | Test and pack only; nothing is published or released                                       |

#### Notes

- NuGet is for the .NET parts of a Unity package (NuGetForUnity-style): point `nuget_project` at a `.csproj`; it is packed with `-p:Version=<package.json version>`.
- Test runs use Docker images from game-ci and can take a long time; the job has a 2-hour limit.
- Not publishing anywhere? Leave both `publish_*` off – you still get tests, the tarball and the release.

---

<a id="unreal"></a>

### Unreal Engine

**Workflow:** `publish-unreal.yml` · **Publishes to:** a GitHub Release (zip per engine version / platform) · **Secrets:** none

> **Two hard limits.** (1) GitHub-hosted runners cannot hold an Unreal Engine install, so this workflow runs on a **self-hosted runner** that already has the engine. (2) **Fab has no public upload API** – you upload the produced zip in the Fab Publisher Portal by hand, once per engine version.

It reads `VersionName` from your `.uplugin`, verifies the tag, runs `RunUAT BuildPlugin`, zips the result as `<Plugin>-<version>-UE<engine>-<OS>.zip`, and attaches it to the release.

**Runner requirements:** Unreal Engine installed at `engine_path`, Git Bash (Windows), `jq`, `zip` (macOS/Linux), and the `gh` CLI if `github_release` is on.

#### Caller workflow

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

#### Inputs

Plus the [common inputs](#common-inputs); `skip_if_published` and `working_directory` do not apply.

| Input              | Type    | Default           | Description                                                                                                  |
| ------------------ | ------- | ----------------- | ------------------------------------------------------------------------------------------------------------ |
| `runner_labels`    | string  | `["self-hosted"]` | JSON array of runner labels, e.g. ["self-hosted","windows","unreal"]                                         |
| `engine_path`      | string  | **required**      | Unreal Engine root on the runner (the folder that contains Engine/), e.g. C:/Program Files/Epic Games/UE_5.6 |
| `engine_version`   | string  | _(empty)_         | Engine version label used in the zip name, e.g. 5.6                                                          |
| `uplugin`          | string  | _(empty)_         | Path to the .uplugin relative to the repo root (empty = the first .uplugin found)                            |
| `target_platforms` | string  | `Win64`           | BuildPlugin -TargetPlatforms value, '+' separated (e.g. Win64+Linux)                                         |
| `extra_args`       | string  | _(empty)_         | Extra arguments appended to the BuildPlugin command                                                          |
| `lfs`              | boolean | `false`           | Fetch Git LFS files                                                                                          |
| `github_release`   | boolean | `true`            | Attach the zip to the GitHub Release of the tag (needs the gh CLI on the runner)                             |
| `dry_run`          | boolean | `false`           | Build and zip, but do not touch the GitHub Release                                                           |

#### Notes

- The `.uplugin` needs a `VersionName` (it is the version compared with the tag).
- The workflow only builds the plugin. Packaging a **game project** needs your own `RunUAT BuildCookRun` command.

---

<a id="wordpress"></a>

### WordPress

**Workflow:** `publish-wordpress.yml` · **Publishes to:** the WordPress.org plugin repository (SVN) · **Auth:** `SVN_USERNAME` + `SVN_PASSWORD`

Built on [10up/action-wordpress-plugin-deploy](https://github.com/10up/action-wordpress-plugin-deploy). The plugin must already be **approved** on WordPress.org (the SVN repository must exist).

Before deploying it checks that the plugin header `Version:` equals the tag **and** equals `Stable tag:` in `readme.txt` – the most common cause of broken WordPress releases.

#### Secrets

| Secret                         | Required                |
| ------------------------------ | ----------------------- |
| `SVN_USERNAME`, `SVN_PASSWORD` | yes (not for `dry_run`) |

#### Caller workflow

```yaml
name: Deploy to WordPress.org
on:
  push:
    tags: ["v*.*.*"]

jobs:
  deploy:
    permissions:
      contents: read
    uses: KMM-ZONE/open-flows/.github/workflows/publish-wordpress.yml@v1
    with:
      slug: my-plugin
      build_command: composer install --no-dev --optimize-autoloader && npm ci && npm run build
    secrets:
      SVN_USERNAME: ${{ secrets.SVN_USERNAME }}
      SVN_PASSWORD: ${{ secrets.SVN_PASSWORD }}
```

#### Inputs

Plus the [common inputs](#common-inputs); `working_directory` does not apply – the plugin must be in the repository root.

| Input           | Type    | Default          | Description                                                                                               |
| --------------- | ------- | ---------------- | --------------------------------------------------------------------------------------------------------- |
| `slug`          | string  | _(empty)_        | Plugin slug on WordPress.org (empty = repository name)                                                    |
| `plugin_file`   | string  | _(empty)_        | Main plugin file holding the 'Version:' header (empty = `<slug>`.php)                                     |
| `build_command` | string  | _(empty)_        | Optional build command run before deploying (e.g. 'composer install --no-dev && npm ci && npm run build') |
| `node_version`  | string  | `24`             | Node.js version (only set up when build_command is not empty)                                             |
| `php_version`   | string  | `8.3`            | PHP version (only set up when build_command is not empty)                                                 |
| `assets_dir`    | string  | `.wordpress-org` | Directory with wordpress.org assets (banners, icons, screenshots)                                         |
| `generate_zip`  | boolean | `true`           | Also build a plugin zip and keep it as a workflow artifact                                                |
| `dry_run`       | boolean | `false`          | Run the deploy action in DRY_RUN mode (nothing is committed to SVN)                                       |

#### Notes

- Put banners, icons and screenshots in `.wordpress-org/` (the `assets_dir` input); the action syncs them to SVN `assets/`.
- Exclude development files from the release with a `.distignore` file.
- With `generate_zip: true` the plugin zip is kept as a workflow artifact – handy for manual QA.
- `dry_run: true` sets the action's `DRY_RUN` mode: it builds and prepares everything but commits nothing.

---

<a id="actions"></a>

## Actions

The publishing workflows are assembled from small **composite actions** that live in [`actions/`](actions), one folder per action, named in kebab-case. They are public too: use any of them as a step in your own workflows.

```yaml
- uses: KMM-ZONE/open-flows/actions/verify-tag@v1
  with:
    version: 1.2.3
```

| Action                                                | What it does                                                                                                                               | Used by                                                                                                                                              |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`check-version`](#check-version)                     | Reads a plain VERSION file and compares it with the newest semver tag.                                                                     | internal pipeline                                                                                                                                    |
| [`create-release`](#create-release)                   | Creates the git tag and GitHub Release for a version and keeps the major alias tag (v1) on the newest stable release of that major.        | internal pipeline                                                                                                                                    |
| [`github-release`](#github-release)                   | Creates a GitHub Release for an existing tag (generated notes, pre-release detection) or, when it already exists, just uploads the assets. | electron, go, swift, unity, unreal                                                                                                                   |
| [`install-node-deps`](#install-node-deps)             | Installs dependencies reproducibly with npm, yarn (classic or berry) or pnpm.                                                              | electron, npm, react-native                                                                                                                          |
| [`packagist-notify`](#packagist-notify)               | Asks Packagist to re-crawl a repository so a new git tag shows up immediately.                                                             | composer, laravel                                                                                                                                    |
| [`read-npm-package`](#read-npm-package)               | Reads name and version from package.json and works out the npm dist-tag for the release.                                                   | electron, npm, react-native, unity                                                                                                                   |
| [`read-python-dist`](#read-python-dist)               | Reads name and version from the built sdist (or wheel), so static and dynamic versions (setuptools_scm, hatch-vcs, ...) are both handled.  | django, python                                                                                                                                       |
| [`registry-version-exists`](#registry-version-exists) | Checks whether an exact version of a package is already published, so a re-run can finish without trying to upload it again.               | cargo, django, electron, flutter, maven, npm, python, react-native, rubygems, unity, wordpress                                                       |
| [`require-secrets`](#require-secrets)                 | Fail early with a clear message when a required secret was not passed to the workflow.                                                     | cargo, django, dotnet, electron, gradle, maven, npm, python, react-native, rubygems, unity, wordpress                                                |
| [`set-published`](#set-published)                     | Sets published=true when any of the given step outcomes is success.                                                                        | cargo, composer, django, dotnet, electron, flutter, go, gradle, laravel, maven, npm, python, react-native, rubygems, swift, unity, unreal, wordpress |
| [`setup-node-project`](#setup-node-project)           | Enables corepack for yarn/pnpm, installs Node.js with optional dependency caching and registry auth.                                       | electron, npm, react-native                                                                                                                          |
| [`verify-tag`](#verify-tag)                           | On tag runs, fail unless the git tag equals tag-prefix + the version (or every version when several are given).                            | cargo, django, dotnet, electron, flutter, gradle, maven, npm, python, react-native, rubygems, unity, unreal, wordpress                               |

### How versions work for actions

- A workflow at tag `v1.4.2` calls its actions at exactly `@v1.4.2`, so one tag is always one consistent snapshot: workflows and actions can never drift apart.
- You normally use the moving major alias (`@v1`) in **your** workflows. Pin `@v1.4.2` or a full commit SHA when you need a fully reproducible build.
- [`scripts/update-version.sh`](#version-sync) rewrites those internal references on every release, and the release pipeline refuses to publish when they differ from `VERSION`.
- This repository's own pipeline (`_publish.yml`, `check-version.yml`, `create-release.yml`, `lint.yml`) calls the local copies (`./actions/...`), so it can release a version before that version's tag exists.

### Rules every action follows

- Composite action (`runs.using: composite`) in `actions/<kebab-case-name>/action.yml`.
- **Leaf**: an action never calls another action of this repository (third-party actions such as `actions/setup-node` are fine).
- Every script step sets `shell: bash` and contains **no** `${{ }}` expression: values arrive through `env:`. This keeps scripts shellcheck-clean and free of injection.
- Secrets are never read from a context; they come in as inputs and are never printed.
- `scripts/validate-actions.py` enforces these rules and checks every call against the action's declared inputs and outputs.

### verify-tag

On tag runs, fail unless the git tag equals tag-prefix + the version (or every version when several are given). On branch runs it does nothing.

| Input        | Default      | Description                                                      |
| ------------ | ------------ | ---------------------------------------------------------------- |
| `version`    | **required** | Version(s) the tag must match, one per line (without the prefix) |
| `tag-prefix` | `v`          | Text in front of the version in the tag (v -> v1.2.3)            |
| `enabled`    | `true`       | Set to 'false' to turn the check off                             |

```yaml
- uses: KMM-ZONE/open-flows/actions/verify-tag@v1
  with:
    version: ${{ steps.meta.outputs.version }}
    tag-prefix: v
```

### require-secrets

Fail early with a clear message when a required secret was not passed to the workflow. Values are never printed.

| Input     | Default      | Description                                                                                                |
| --------- | ------------ | ---------------------------------------------------------------------------------------------------------- |
| `secrets` | **required** | One NAME=value per line (the value is the secret itself). A value may span several lines (PEM / GPG keys). |
| `mode`    | `all`        | 'all' = every secret must be set, 'any' = at least one must be set                                         |
| `enabled` | `true`       | Set to 'false' to skip the check (for example on a dry run)                                                |

```yaml
- uses: KMM-ZONE/open-flows/actions/require-secrets@v1
  with:
    enabled: ${{ !inputs.dry_run }}
    secrets: |
      NPM_TOKEN=${{ secrets.NPM_TOKEN }}
```

### set-published

Sets published=true when any of the given step outcomes is success. Call it with an always() condition so it also runs after failures.

| Input      | Default      | Description                                                                         |
| ---------- | ------------ | ----------------------------------------------------------------------------------- |
| `outcomes` | **required** | Step outcomes (success/failure/skipped/cancelled), separated by spaces or new lines |

| Output      | Meaning                                        |
| ----------- | ---------------------------------------------- |
| `published` | 'true' when at least one outcome was 'success' |

```yaml
- id: result
  if: always()
  uses: KMM-ZONE/open-flows/actions/set-published@v1
  with:
    outcomes: ${{ steps.publish.outcome }}
```

### registry-version-exists

Checks whether an exact version of a package is already published, so a re-run can finish without trying to upload it again. Supports pub.dev, npm, PyPI, crates.io, RubyGems, Maven Central and WordPress.org.

| Input          | Default      | Description                                                                                       |
| -------------- | ------------ | ------------------------------------------------------------------------------------------------- |
| `registry`     | **required** | pub \| npm \| pypi \| crates \| rubygems \| maven-central \| wordpress                            |
| `name`         | **required** | Package name (Maven: artifactId, WordPress: plugin slug)                                          |
| `version`      | **required** | Exact version to look for                                                                         |
| `group`        | _(empty)_    | Maven groupId (maven-central only)                                                                |
| `registry-url` | _(empty)_    | Base URL of the registry (empty = the public default; PyPI: `https://test.pypi.org` for TestPyPI) |
| `auth-token`   | _(empty)_    | Token for private npm registries                                                                  |

| Output   | Meaning                                      |
| -------- | -------------------------------------------- |
| `exists` | 'true' when the version is already published |

```yaml
- id: exists
  uses: KMM-ZONE/open-flows/actions/registry-version-exists@v1
  with:
    registry: pypi
    name: my-package
    version: 1.2.3
- if: steps.exists.outputs.exists != 'true'
  run: echo "not published yet - go ahead"
```

### read-npm-package

Reads name and version from package.json and works out the npm dist-tag for the release.

| Input             | Default   | Description                                                                                    |
| ----------------- | --------- | ---------------------------------------------------------------------------------------------- |
| `directory`       | `.`       | Folder containing package.json                                                                 |
| `dist-tag`        | _(empty)_ | Force a dist-tag. Empty = latest, or the pre-release id (1.0.0-beta.1 -> beta, otherwise next) |
| `fail-if-private` | `true`    | Fail when package.json has "private": true (npm refuses to publish those)                      |

| Output     | Meaning                       |
| ---------- | ----------------------------- |
| `name`     | Package name                  |
| `version`  | Package version               |
| `dist-tag` | npm dist-tag to publish under |

```yaml
- id: meta
  uses: KMM-ZONE/open-flows/actions/read-npm-package@v1
  with:
    directory: packages/ui
- run: echo "${{ steps.meta.outputs.name }} ${{ steps.meta.outputs.version }} -> ${{ steps.meta.outputs.dist-tag }}"
```

### setup-node-project

Enables corepack for yarn/pnpm, installs Node.js with optional dependency caching and registry auth.

| Input               | Default   | Description                                                                             |
| ------------------- | --------- | --------------------------------------------------------------------------------------- |
| `node-version`      | `24`      | Node.js version                                                                         |
| `package-manager`   | `npm`     | npm \| yarn \| pnpm                                                                     |
| `registry-url`      | _(empty)_ | npm registry URL (enables NODE_AUTH_TOKEN based auth). Empty = leave the registry alone |
| `cache`             | `true`    | Cache the package-manager store ('true' needs a lock file)                              |
| `install-directory` | `.`       | Folder that holds the lock file                                                         |

```yaml
- uses: KMM-ZONE/open-flows/actions/setup-node-project@v1
  with:
    package-manager: pnpm
    registry-url: https://registry.npmjs.org
```

### install-node-deps

Installs dependencies reproducibly with npm, yarn (classic or berry) or pnpm.

| Input             | Default | Description                                         |
| ----------------- | ------- | --------------------------------------------------- |
| `package-manager` | `npm`   | npm \| yarn \| pnpm                                 |
| `directory`       | `.`     | Folder to install in (workspace root for monorepos) |

```yaml
- uses: KMM-ZONE/open-flows/actions/install-node-deps@v1
  with:
    package-manager: yarn
```

### read-python-dist

Reads name and version from the built sdist (or wheel), so static and dynamic versions (setuptools_scm, hatch-vcs, ...) are both handled.

| Input            | Default | Description                                                |
| ---------------- | ------- | ---------------------------------------------------------- |
| `directory`      | `.`     | Project folder (the one that contains dist/)               |
| `dist-directory` | `dist`  | Folder with the built distributions, relative to directory |

| Output    | Meaning                                    |
| --------- | ------------------------------------------ |
| `name`    | Distribution name                          |
| `version` | Distribution version (normalised, PEP 440) |

```yaml
- run: python -m build
- id: meta
  uses: KMM-ZONE/open-flows/actions/read-python-dist@v1
- run: echo "${{ steps.meta.outputs.name }} ${{ steps.meta.outputs.version }}"
```

### packagist-notify

Asks Packagist to re-crawl a repository so a new git tag shows up immediately.

| Input         | Default   | Description                                                                |
| ------------- | --------- | -------------------------------------------------------------------------- |
| `username`    | _(empty)_ | Packagist username                                                         |
| `token`       | _(empty)_ | Packagist API token                                                        |
| `package-url` | _(empty)_ | Repository URL registered on Packagist (empty = this repository on GitHub) |

| Output     | Meaning                                           |
| ---------- | ------------------------------------------------- |
| `notified` | 'true' when Packagist accepted the update request |

```yaml
- uses: KMM-ZONE/open-flows/actions/packagist-notify@v1
  with:
    username: ${{ secrets.PACKAGIST_USERNAME }}
    token: ${{ secrets.PACKAGIST_API_TOKEN }}
```

### github-release

Creates a GitHub Release for an existing tag (generated notes, pre-release detection) or, when it already exists, just uploads the assets. Safe to call from several jobs at once.

| Input                  | Default               | Description                                                                                          |
| ---------------------- | --------------------- | ---------------------------------------------------------------------------------------------------- |
| `tag`                  | **required**          | Tag of the release                                                                                   |
| `version`              | _(empty)_             | Version, used to mark pre-releases (a '-' in the version = pre-release). Empty = derive from the tag |
| `assets`               | _(empty)_             | Files to attach, one path or glob per line. Every pattern must match something                       |
| `optional-assets`      | _(empty)_             | Files to attach when present, one path or glob per line                                              |
| `generate-notes`       | `true`                | Generate release notes automatically                                                                 |
| `notes`                | _(empty)_             | Text placed above the generated notes                                                                |
| `require-existing-tag` | `true`                | Refuse to create a tag: the tag must already exist                                                   |
| `token`                | `${{ github.token }}` | Token with contents: write                                                                           |

| Output    | Meaning                                                                    |
| --------- | -------------------------------------------------------------------------- |
| `url`     | URL of the release                                                         |
| `created` | 'true' when this call created the release, 'false' when it already existed |

```yaml
- uses: KMM-ZONE/open-flows/actions/github-release@v1
  with:
    tag: ${{ github.ref_name }}
    assets: |
      dist/*.zip
      dist/checksums.txt
```

Needs `contents: write` on the job. It is safe to call from several jobs at once: the first creates the release, the others only upload their files.

### check-version

Reads a plain VERSION file and compares it with the newest semver tag. bumped=true means the version is higher than every tag (safe to release).

| Input          | Default   | Description                                                            |
| -------------- | --------- | ---------------------------------------------------------------------- |
| `version-file` | `VERSION` | Plain-text version file (MAJOR.MINOR.PATCH[-prerelease], no leading v) |
| `tag-prefix`   | `v`       | Prefix of release tags (v -> v1.2.3)                                   |
| `require-bump` | `false`   | Fail when the version is not bumped (use as a pull-request gate)       |

| Output           | Meaning                                                                   |
| ---------------- | ------------------------------------------------------------------------- |
| `version`        | Version read from the version file                                        |
| `tag`            | Tag a release of this version would use (tag-prefix + version)            |
| `latest-version` | Highest existing semver tag without the prefix (empty when there is none) |
| `bumped`         | 'true' when the version is higher than the latest tag                     |
| `prerelease`     | 'true' when the version has a pre-release part                            |
| `reason`         | first-release \| bumped \| same-version \| lower-version \| tag-exists    |

```yaml
- uses: actions/checkout@v7
  with:
    fetch-depth: 0
- id: version
  uses: KMM-ZONE/open-flows/actions/check-version@v1
- if: steps.version.outputs.bumped == 'true'
  run: echo "ready to release ${{ steps.version.outputs.version }}"
```

### create-release

Creates the git tag and GitHub Release for a version and keeps the major alias tag (v1) on the newest stable release of that major. Run actions/checkout (any depth) first so the repository is available.

| Input              | Default               | Description                                                                               |
| ------------------ | --------------------- | ----------------------------------------------------------------------------------------- |
| `version`          | **required**          | Version to release, e.g. 1.2.3 (must equal the content of the version file at the commit) |
| `version-file`     | `VERSION`             | Plain-text version file                                                                   |
| `tag-prefix`       | `v`                   | Prefix of release tags (v -> v1.2.3)                                                      |
| `sha`              | _(empty)_             | Commit to tag (empty = the checked-out commit)                                            |
| `notes`            | _(empty)_             | Text placed above the generated release notes                                             |
| `update-major-tag` | `true`                | Move the major alias tag (v1) when this is the newest stable release of its major         |
| `dry-run`          | `false`               | Only print what would be created                                                          |
| `token`            | `${{ github.token }}` | Token with contents: write                                                                |

| Output     | Meaning                            |
| ---------- | ---------------------------------- |
| `tag`      | Tag that was (or would be) created |
| `url`      | URL of the GitHub Release          |
| `released` | 'true' when a release was created  |

```yaml
- uses: actions/checkout@v7
- uses: KMM-ZONE/open-flows/actions/create-release@v1
  with:
    version: 1.2.3
```

Needs `contents: write` on the job. See [Release tooling](#release-tooling) for the exact rules.

---

<a id="release-tooling"></a>

## Release tooling: check-version and create-release

Two actions for **any repository that keeps its version in a plain `VERSION` file**. This repository uses them to release itself (see [Releasing this repository](#releasing-this-repository)).

The `VERSION` file contains just the number – `1.2.3`, or `1.3.0-rc.1` for a pre-release – with no leading `v`.

### What check-version decides

It compares `VERSION` with the highest existing semver tag using full [SemVer 2.0.0](https://semver.org) precedence (`1.10.0 > 1.9.0`, `1.0.0-rc.2 > 1.0.0-rc.1`, `1.0.0 > 1.0.0-rc.2`; build metadata is ignored). Tags that are not semver (aliases such as `v1`, or `nightly`) are ignored.

| `bumped` | `reason`        | Meaning                                                |
| -------- | --------------- | ------------------------------------------------------ |
| `true`   | `first-release` | The repository has no semver tag yet                   |
| `true`   | `bumped`        | `VERSION` is higher than every existing tag            |
| `false`  | `same-version`  | Equal to the latest tag (ignoring build metadata)      |
| `false`  | `tag-exists`    | The tag for this exact version already exists          |
| `false`  | `lower-version` | Lower than the latest tag (for example a stale branch) |

### What create-release does

It creates the tag `vX.Y.Z` on the given commit and a GitHub Release with generated notes. It also keeps the **major alias** (`v1`) on the newest stable release of that major, and it is careful about order:

- a hotfix `1.0.1` released after `2.0.0` is **not** marked _Latest_ and does not move `v1` if `1.1.0` already exists
- a pre-release (`2.0.0-rc.1`) is marked _pre-release_, never _Latest_, and never moves an alias
- it refuses to run if the tag already exists, or if `VERSION` at that commit differs from the requested version

The full inputs and outputs are in the [Actions reference](#actions).

### Use them in your repository

```yaml
name: Release
on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0

      - id: version
        uses: KMM-ZONE/open-flows/actions/check-version@v1

      - if: steps.version.outputs.bumped == 'true'
        uses: KMM-ZONE/open-flows/actions/create-release@v1
        with:
          version: ${{ steps.version.outputs.version }}
```

Require a version bump on every pull request (the check fails when `VERSION` was not raised):

```yaml
name: Version bumped?
on: pull_request

jobs:
  version:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
      - uses: KMM-ZONE/open-flows/actions/check-version@v1
        with:
          require-bump: true
```

#### Notes

- Tags and releases created with the built-in `GITHUB_TOKEN` **do not trigger other workflows** (a GitHub rule that prevents loops). If a tag-triggered publishing workflow must follow, call it in the same workflow with `needs:` instead of relying on `on: push: tags`.
- Moving the alias needs permission to update tags. If you protect tags with a ruleset, allow the _GitHub Actions_ app to bypass it for the alias pattern (`v[0-9]*`).
- Do not keep the version in two places by hand. If your package manifest also carries a version, keep it equal to `VERSION` (or generate one from the other).

---

<a id="migrating"></a>

## Migrating existing per-repo pipelines

Replace the whole pipeline in each repository with a caller of roughly ten lines. Three real examples:

### Python

Before: 25 lines that run `python setup.py sdist bdist_wheel` and `twine upload` with `secrets.PYPI_API_TOKEN`. After:

```yaml
name: Publish to PyPI
on:
  push:
    tags: ["v*.*.*"]

jobs:
  publish:
    permissions:
      contents: read
    uses: KMM-ZONE/open-flows/.github/workflows/publish-python.yml@v1
    with:
      python_version: "3.12"
      run_tests: false # the old pipeline had no test step
    secrets:
      PYPI_API_TOKEN: ${{ secrets.PYPI_API_TOKEN }}
```

The secret keeps its name, so nothing changes in the repository settings. Builds now use `python -m build` (which also works for `setup.py` projects) and the upload is skipped when the version already exists.

### Flutter

Before: a 90-line pub.dev pipeline (tag check, "is it newer than the last release" check, format, analyze, test, dry-run, publish on `macos-15`). After:

```yaml
name: Publish to pub.dev
run-name: ${{ github.ref_name }}
on:
  push:
    tags: ["v*"]

concurrency:
  group: publish-${{ github.ref }}
  cancel-in-progress: false

jobs:
  publish:
    permissions:
      contents: read
      id-token: write
    uses: KMM-ZONE/open-flows/.github/workflows/publish-flutter.yml@v1
    with:
      runner: macos-15
      check_format: true
```

What is equivalent and what changed:

| Old behaviour                                                                                    | In the central workflow                                                                                                                                  |
| ------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Tag must equal `v` + pubspec version                                                             | Same (`verify_tag`, `tag_prefix`)                                                                                                                        |
| `dart format`, `flutter analyze`, `flutter test`, `pub publish --dry-run`, `pub publish --force` | Same order. `check_format` is **off by default** (set it to `true` to keep the old behaviour). Analysis runs on the whole package rather than `lib test` |
| Skip when the version is **not newer than the latest git tag**                                   | Replaced by _skip when this exact version is already on pub.dev_ (`skip_if_published`). A lower, unpublished version would now be published              |
| Actions pinned to SHAs                                                                           | Same, maintained centrally                                                                                                                               |
| Concurrency group                                                                                | Stays in the caller, as shown                                                                                                                            |

### npm

```yaml
name: Publish to npm
on:
  push:
    tags: ["v*.*.*"]

concurrency:
  group: publish-${{ github.ref }}
  cancel-in-progress: false

jobs:
  publish:
    permissions:
      contents: read
      id-token: write
    uses: KMM-ZONE/open-flows/.github/workflows/publish-npm.yml@v1
    with:
      node_version: "24"
      provenance: true
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

---

<a id="security-notes"></a>

## Security notes

- **Pinned, current actions.** GitHub's own `actions/*` use the latest major tag (`actions/checkout@v7`); every third-party action is pinned to a full commit SHA with its version in a comment, because a third party can move a tag. Dependabot checks both daily ([details](#dependabot)). In your own callers you can pin _this_ repository the same way: `uses: KMM-ZONE/open-flows/.github/workflows/publish-npm.yml@<full-sha> # v1.0.0`.
- **Immutable internals.** A workflow at tag `vX.Y.Z` calls this repository's actions at exactly `@vX.Y.Z`, and the release pipeline refuses to publish when any of those references differs from `VERSION` ([details](#version-sync)).
- **Least privilege.** Each workflow declares the minimum `permissions` (see [Permissions](#permissions)). Checkouts use `persist-credentials: false`.
- **Secrets are scoped to the steps that need them.** They are passed through `env:` to the publishing step only, never interpolated into shell scripts. Inputs are read from `env:` too, so a crafted input cannot inject commands.
- **Protect your release tags.** Anyone who can push a `v*` tag can trigger a publish. Use a repository ruleset to restrict tag creation, and keep the publishing credentials in a repository or organisation secret that only trusted workflows can read.
- **Never trigger these workflows from `pull_request_target`** or from untrusted forks.
- **Prefer narrowly scoped tokens** (one package, publish-only) and rotate them; several registries now expire tokens.

<a id="troubleshooting"></a>

## Troubleshooting

| Symptom                                                                                    | Cause and fix                                                                                                                                                |
| ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| _"The nested job … is requesting 'id-token: write', but is only allowed 'id-token: none'"_ | Add `permissions:` to the **calling** job (see [Permissions](#permissions))                                                                                  |
| _"The NPM_TOKEN secret is not set"_ (or similar)                                           | The caller did not pass the secret. Add it under `secrets:` – secrets are not inherited automatically                                                        |
| _"Tag 'v1.2.3' must match the package version"_                                            | Bump the version in the manifest **before** tagging, or fix the `tag_prefix`                                                                                 |
| _"Unable to resolve action `KMM-ZONE/open-flows/actions/…@v1.2.3`"_                        | You are calling a commit that is not a release (for example `@main`). Use a release tag: the actions are referenced by the exact version of the tag you call |
| _"Unable to resolve action … workflow was not found"_                                      | The `@v1` tag does not exist yet, or the path/ref is wrong. See [Releasing this repository](#releasing-this-repository)                                      |
| Run is green but `published` is `false`                                                    | The version already exists on the registry (`skip_if_published`), or `dry_run` is on. Look for the `::notice::` line in the log                              |
| PyPI: _403 Invalid or non-existent authentication_                                         | Token pasted with spaces/newline, TestPyPI token used for PyPI (or vice versa), or the project-scoped token belongs to another project                       |
| npm: `EOTP` / `E403`                                                                       | The token needs permission to publish without a one-time password, or does not cover this package/scope                                                      |
| npm: _"You must specify a tag using --tag when publishing a prerelease"_                   | Not expected here (dist-tags are chosen automatically). Check you are not overriding `publish_command`                                                       |
| Maven: _"Deployment … Invalid signature"_ / _"Could not find a public key"_                | The public key is not on a keyserver Central checks, or `GPG_PRIVATE_KEY` was pasted without the BEGIN/END lines                                             |
| Maven: profile `release` has no effect                                                     | A `-P` for a profile that does not exist is only a warning in Maven. Add the profile to the pom (see [Maven](#maven))                                        |
| Cargo: _"files in the working directory contain changes"_                                  | Commit `Cargo.lock` or set `allow_dirty: true`                                                                                                               |
| WordPress: _"Stable tag … must match"_                                                     | Update `Stable tag:` in `readme.txt` and `Version:` in the main plugin file to the same value as the tag                                                     |
| _"Missing secret(s): …"_ from `require-secrets`                                            | The caller did not pass those secrets under `secrets:` (see [Passing secrets](#passing-secrets))                                                             |
| Go: _"Module path … must end in /v2"_                                                      | Major versions ≥ 2 need the suffix in `go.mod` and in all import paths                                                                                       |

---

<a id="maintaining"></a>

## Maintaining this repository

```text
VERSION                              # the version of this repository (plain text, e.g. 1.0.0)
actions/                             # reusable composite actions, one kebab-case folder each
├── check-version/            ├── read-npm-package/
├── create-release/           ├── read-python-dist/
├── github-release/           ├── registry-version-exists/
├── install-node-deps/        ├── require-secrets/
├── packagist-notify/         ├── set-published/
├── setup-node-project/       └── verify-tag/
scripts/
├── update-version.sh                # set / check the version everywhere
├── validate-actions.py              # action rules + every call checked against inputs/outputs + shellcheck
├── check-actions-latest.sh          # reports third-party actions that are not on their latest release
├── test-semver.sh                   # tests the semver logic shared by check-version and create-release
└── test-update-version.sh           # tests update-version.sh
.github/
├── dependabot.yml                   # daily bumps of every third-party action reference
└── workflows/
    ├── _publish.yml                 # everything for a push to main in ONE run: lint, check-version, verify-sync, create-release
    ├── check-version.yml            # internal: runs ./actions/check-version
    ├── create-release.yml           # internal: runs ./actions/create-release
    ├── lint.yml                     # actionlint, yamllint, markdownlint, action validation, version sync, tests
    └── publish-*.yml                # the 18 publishing workflows
.yamllint.yml  .markdownlint.jsonc  .editorconfig
```

- **Add an ecosystem:** copy the closest `publish-*.yml`, keep the shared inputs (`working_directory`, `verify_tag`, `tag_prefix`, `skip_if_published`, `dry_run`) and outputs (`version`, `published`), build it from the actions above, declare every secret under `workflow_call.secrets`, add a section here, and raise `VERSION` (minor).
- **Add an action:** create `actions/<kebab-case-name>/action.yml` following the [rules](#actions), add a section to the Actions reference, and run `python3 scripts/validate-actions.py`.

<a id="releasing-this-repository"></a>

### Releasing this repository

This repository versions itself with the plain-text **`VERSION`** file and releases through [`_publish.yml`](.github/workflows/_publish.yml) (the underscore marks it as internal – other repositories should not call it).

```text
push to main ─┬─► lint ───────────────────────────────────────────┐
              └─► check-version ─┬─ bumped ─► verify-sync ─────────┴─► create-release  (tag vX.Y.Z · GitHub Release · move vX alias)
                                 └─ not bumped ─► stop                (no tag, no release; the run summary says why)
```

One push produces **one** workflow run (`_publish`): lint, the version check and the release are jobs inside it. Pull requests run `Lint` on their own.

To release:

```bash
scripts/update-version.sh --v=1.1.0        # VERSION + every action reference + README aliases
git add -A && git commit -m "chore: release 1.1.0"
git push                                   # or open a pull request and merge it
```

Merging to `main` is all that is left to do: the pipeline creates the tag, the GitHub Release and the major alias.

| Change                                           | Bump                      | Examples                                                                                             |
| ------------------------------------------------ | ------------------------- | ---------------------------------------------------------------------------------------------------- |
| Fix, internal refactor, dependency/action update | **patch** `1.0.0 → 1.0.1` | corrected a shell step, Dependabot bump                                                              |
| New workflow, action, optional input or output   | **minor** `1.0.0 → 1.1.0` | a new ecosystem, a new `with:` option                                                                |
| Anything that can break a caller on `@v1`        | **major** `1.4.2 → 2.0.0` | renamed/removed input, new required secret, new `permissions` requirement, changed default behaviour |

What happens on each push to `main`:

| `VERSION` compared with the latest tag | Result                                                                                                                                             |
| -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Higher (or no tag exists yet)          | The sync check runs next to lint; if both pass the tag, release and alias are created. If either fails nothing is tagged and the next push retries |
| Equal, or its tag already exists       | Lint still runs; nothing is released                                                                                                               |
| Lower                                  | Lint still runs; nothing is released (a note in the run summary)                                                                                   |
| Pre-release (`1.3.0-rc.1`)             | Released as a GitHub _pre-release_; `@v1` is **not** moved to it                                                                                   |

A manual run (_Actions → \_publish → Run workflow_) with **dry run** on shows what would be released without creating anything.

<a id="version-sync"></a>

### Keeping versions in sync

All versions in the repository must agree. `scripts/update-version.sh` is the only thing you need:

| Command                                         | Effect                                                                                                                                                                                  |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `scripts/update-version.sh --v=2.0.1`           | Writes `VERSION`, then rewrites every `KMM-ZONE/open-flows/actions/<name>@v…` reference in `.github/workflows/*.yml` to `@v2.0.1`, and every major alias in the Markdown files to `@v2` |
| `scripts/update-version.sh --v=2.0.1 --dry-run` | Shows what would change, writes nothing                                                                                                                                                 |
| `scripts/update-version.sh --check`             | Verifies that everything matches `VERSION`; exits non-zero and shows the offending lines otherwise                                                                                      |
| `scripts/update-version.sh --show`              | Prints the current version                                                                                                                                                              |

Details:

- A version lower than the current one is refused unless you add `--force`.
- Pre-releases (`--v=3.0.0-rc.1`) update the workflow references to the exact pre-release but leave the README on the stable major alias.
- Exact references in prose (`…publish-npm.yml@v1.2.3`) are never touched; only major aliases are.
- `--check` runs in `lint.yml` on every change and as its own job (**verify-sync**) in `_publish.yml` before a release is created, so a release can never ship with mismatched references.

<a id="dependabot"></a>

### Dependabot and action versions

Every third-party `uses:` reference should be on the latest release of its action.

| Kind of action                                      | Reference style                                   | Example                                         |
| --------------------------------------------------- | ------------------------------------------------- | ----------------------------------------------- |
| GitHub's own `actions/*`                            | latest **major tag**                              | `actions/checkout@v7`                           |
| Everything else (`pypa/…`, `ruby/…`, `gradle/…`, …) | **commit SHA** + version comment                  | `ruby/setup-ruby@be3c7df…  # v1.343.0`          |
| This repository's own actions                       | **exact version**, managed by `update-version.sh` | `KMM-ZONE/open-flows/actions/verify-tag@v1.0.0` |

- [`.github/dependabot.yml`](.github/dependabot.yml) checks **daily** and opens one grouped pull request. For SHA-pinned actions Dependabot rewrites both the SHA and the `# vX.Y.Z` comment. It ignores this repository's own actions.
- `lint.yml` also runs `scripts/check-actions-latest.sh`, which compares every third-party reference with the action's newest release and reports drift as a **warning**, so an outdated action is visible before Dependabot's pull request is merged. Run it with `STRICT=1` to make drift fail.
- **Merging a Dependabot pull request does not release anything**, because `VERSION` did not change. When you want consumers on `@v1` to get the update, run `scripts/update-version.sh --v=<next patch>` in the pull request or right after merging.
- In _your_ repositories Dependabot will propose `@v1 → @v2` for these workflows when a new major is released – a good moment to read the release notes.

<a id="linting"></a>

### Linting and warnings

`lint.yml` runs on every pull request, and on every push to `main` as the first job of `_publish.yml` (so a push never starts a second, separate lint run):

| Check                                           | Tool                                                       | Config                                       |
| ----------------------------------------------- | ---------------------------------------------------------- | -------------------------------------------- |
| Workflow syntax, expressions, permissions       | `actionlint` (with `shellcheck` on every script)           | –                                            |
| Scripts in workflows and actions at style level | `shellcheck` via `scripts/validate-actions.py`             | –                                            |
| Action rules and every call's inputs/outputs    | `scripts/validate-actions.py`                              | –                                            |
| YAML style                                      | `yamllint`                                                 | [`.yamllint.yml`](.yamllint.yml)             |
| Markdown style                                  | `markdownlint`                                             | [`.markdownlint.jsonc`](.markdownlint.jsonc) |
| Versions in sync                                | `scripts/update-version.sh --check`                        | –                                            |
| Semver logic, version script                    | `scripts/test-semver.sh`, `scripts/test-update-version.sh` | –                                            |

The linter configs only switch off rules that do not fit this repository: line length (scripts and `${{ }}` expressions are long), the `---` document marker, and `on:` being read as a boolean. Everything else is fixed in the files rather than silenced.

> If you ever make this repository private, enable _Settings → Actions → General → Access_ so other repositories may use the workflows and actions.
