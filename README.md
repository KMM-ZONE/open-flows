# Open Flows

[![Release](https://img.shields.io/github/v/release/KMM-ZONE/open-flows?label=release)](https://github.com/KMM-ZONE/open-flows/releases)
[![Lint](https://github.com/KMM-ZONE/open-flows/actions/workflows/lint.yml/badge.svg)](https://github.com/KMM-ZONE/open-flows/actions/workflows/lint.yml)

**Open Flows** is the public collection of reusable GitHub Actions workflows and composite actions maintained by **[KMM-ZONE](https://kmm.zone)** (kmm.zone).
Anyone can call them from any repository – public or private – with a few lines of YAML, instead of copying a 100-line pipeline into every project.

- 📦 **Publishing workflows** – one per ecosystem (**17 ecosystems, 18 workflows**), identical inputs and outputs everywhere
- 🧩 **Reusable actions** – the building blocks of those workflows live in [`actions/`](docs/actions.md) as small composite actions with kebab-case names. Use them on their own in any workflow
- 🏷️ **Release tooling** – [`check-version` and `create-release`](docs/release-tooling.md), driven by a plain `VERSION` file. This repository releases itself with them
- 🔐 **Public code, private credentials** – nothing is downloaded from an external service; the only secrets involved are the ones _you_ store in _your_ repository
- ✅ A release is a pushed tag. The publishing workflows refuse to publish when the tag and the manifest version disagree
- 🧪 Every workflow has `dry_run`, and skips versions that are already published (re-runs are safe)
- 🔔 **Update notices** – a note in the job summary when a newer release exists, so nobody has to watch this repository ([`inform_new_version`](docs/update-notices.md))
- 📌 Always current: GitHub's own `actions/*` use the latest major tag, third-party actions are pinned to commit SHAs, and Dependabot checks both daily

**Using it:** call a workflow as `KMM-ZONE/open-flows/.github/workflows/publish-npm.yml@v1` or an action as `KMM-ZONE/open-flows/actions/verify-tag@v1`. The `@v1` alias follows every compatible update; `@v1.2.3` or a full commit SHA is fully reproducible. See [Releasing this repository](docs/releasing.md#releasing-this-repository) for how versions are produced.

## Documentation

| Page                                             | What is in it                                                                                                                  |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
| [Conventions](docs/conventions.md)               | Shared inputs and outputs, permissions, passing secrets, dry runs, why tokens and not OIDC, and the full **secrets reference** |
| [Publishing workflows](docs/workflows/README.md) | One page per ecosystem: one-time setup, secrets, a ready-to-copy caller and the inputs                                         |
| [Update notices](docs/update-notices.md)         | The job-summary note about newer releases and the `inform_new_version` switch                                                  |
| [Actions](docs/actions.md)                       | The reusable composite actions and how to use them on their own                                                                |
| [Release tooling](docs/release-tooling.md)       | `check-version` and `create-release` for repositories with a plain `VERSION` file                                              |
| [Migrating](docs/migrating.md)                   | Replace an existing per-repository pipeline with a caller                                                                      |
| [Security notes](docs/security.md)               | Pinning, least privilege, secret handling                                                                                      |
| [Troubleshooting](docs/troubleshooting.md)       | Common errors and their fixes                                                                                                  |
| [Maintaining](docs/maintaining.md)               | Repository layout, adding an ecosystem or action, linting and warnings                                                         |
| [Releasing and versioning](docs/releasing.md)    | How this repository is released, `update-version.sh`, Dependabot                                                               |

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

<a id="supported-ecosystems"></a>

## Supported ecosystems

| Ecosystem                                          | Workflow file              | Publishes to                                              | Secrets you need to add                                                                                                                                                                     |
| -------------------------------------------------- | -------------------------- | --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Flutter / Dart](docs/workflows/flutter.md)        | `publish-flutter.yml`      | pub.dev                                                   | **None** – uses pub.dev automated publishing (GitHub OIDC)                                                                                                                                  |
| [Node.js (npm)](docs/workflows/npm.md)             | `publish-npm.yml`          | npmjs.com or any npm registry                             | `NPM_TOKEN`                                                                                                                                                                                 |
| [React Native](docs/workflows/react-native.md)     | `publish-react-native.yml` | npm                                                       | `NPM_TOKEN`                                                                                                                                                                                 |
| [Electron](docs/workflows/electron.md)             | `publish-electron.yml`     | npm + installers on the GitHub Release                    | `NPM_TOKEN` · optional signing: `CSC_LINK`, `CSC_KEY_PASSWORD`, `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID`, `WIN_CSC_LINK`, `WIN_CSC_KEY_PASSWORD`                          |
| [Python](docs/workflows/python.md)                 | `publish-python.yml`       | PyPI / TestPyPI                                           | `PYPI_API_TOKEN`                                                                                                                                                                            |
| [Django](docs/workflows/django.md)                 | `publish-django.yml`       | PyPI (after a Python × Django test matrix)                | `PYPI_API_TOKEN`                                                                                                                                                                            |
| [.NET](docs/workflows/dotnet.md)                   | `publish-dotnet.yml`       | NuGet                                                     | `NUGET_API_KEY`                                                                                                                                                                             |
| [Java / Kotlin – Maven](docs/workflows/maven.md)   | `publish-maven.yml`        | Maven Central (Central Portal)                            | `MAVEN_CENTRAL_USERNAME`, `MAVEN_CENTRAL_PASSWORD`, `GPG_PRIVATE_KEY`, `GPG_PASSPHRASE`                                                                                                     |
| [Java / Kotlin – Gradle](docs/workflows/gradle.md) | `publish-gradle.yml`       | Maven Central or Gradle Plugin Portal                     | Central: `MAVEN_CENTRAL_USERNAME`, `MAVEN_CENTRAL_PASSWORD`, `SIGNING_KEY`, `SIGNING_PASSWORD` (+ optional `SIGNING_KEY_ID`) · Plugin Portal: `GRADLE_PUBLISH_KEY`, `GRADLE_PUBLISH_SECRET` |
| [Rust](docs/workflows/rust.md)                     | `publish-cargo.yml`        | crates.io                                                 | `CARGO_REGISTRY_TOKEN`                                                                                                                                                                      |
| [Go](docs/workflows/go.md)                         | `publish-go.yml`           | Go module proxy (a git tag _is_ the release)              | **None**                                                                                                                                                                                    |
| [PHP / Composer](docs/workflows/php.md)            | `publish-composer.yml`     | Packagist                                                 | `PACKAGIST_USERNAME`, `PACKAGIST_API_TOKEN` _(optional when the Packagist GitHub hook is active)_                                                                                           |
| [Laravel](docs/workflows/laravel.md)               | `publish-laravel.yml`      | Packagist (after a PHP × Laravel test matrix)             | `PACKAGIST_USERNAME`, `PACKAGIST_API_TOKEN` _(optional, as above)_                                                                                                                          |
| [Ruby](docs/workflows/ruby.md)                     | `publish-rubygems.yml`     | RubyGems.org                                              | `RUBYGEMS_API_KEY`                                                                                                                                                                          |
| [Swift / iOS](docs/workflows/swift.md)             | `publish-swift.yml`        | SwiftPM (a git tag) + optional CocoaPods + GitHub Release | **None** for SwiftPM · `COCOAPODS_TRUNK_TOKEN` for CocoaPods                                                                                                                                |
| [Unity](docs/workflows/unity.md)                   | `publish-unity.yml`        | npm / NuGet / GitHub Release. **Asset Store is manual**   | `NPM_TOKEN` and/or `NUGET_API_KEY` · optional tests: `UNITY_LICENSE`, `UNITY_EMAIL`, `UNITY_PASSWORD` (`UNITY_SERIAL` for Plus/Pro)                                                         |
| [Unreal Engine](docs/workflows/unreal.md)          | `publish-unreal.yml`       | GitHub Release zip. **Fab is manual**                     | **None** (needs a self-hosted runner with the engine)                                                                                                                                       |
| [WordPress](docs/workflows/wordpress.md)           | `publish-wordpress.yml`    | WordPress.org plugin repository (SVN)                     | `SVN_USERNAME`, `SVN_PASSWORD`                                                                                                                                                              |

`GITHUB_TOKEN` is created automatically for every run – it is never something you add yourself.

> **Three registries have no upload API.** Go and Swift Package Manager publish by _git tag_, so those workflows validate and index rather than upload. The Unity Asset Store and Fab (Unreal) have no public upload API at all, so those workflows produce the artefact and you upload it in the vendor's portal. Details are in each section.

## License and contact

Maintained by [KMM-ZONE](https://kmm.zone). Questions and ideas: open an issue on this repository.
