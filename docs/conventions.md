# Conventions shared by every workflow

[← README](../README.md) · [Documentation index](README.md)

<a id="common-inputs"></a>

## Inputs and outputs

These inputs behave the same in every workflow where they exist (each section's table lists only the inputs that are specific to that workflow or have a different default, plus `dry_run`, because what exactly it skips varies):

| Input | Default | Meaning |
| --- | --- | --- |
| `working_directory` | `.` | Folder of the package inside the repository (monorepos) |
| `verify_tag` | `true` | On tag pushes, fail unless the tag equals `tag_prefix` + the version found in the manifest |
| `tag_prefix` | `v` | Text in front of the version in your tags (`v1.2.3` → `v`). For monorepos use e.g. `my_pkg-v` |
| `skip_if_published` | `true` | If the exact version is already on the registry, finish successfully without publishing (safe re-runs) |
| `dry_run` | `false` | Run everything except the final upload |
| `inform_new_version` | `all` | Mention newer releases of these workflows in the job summary: `none`, `major-only`, `major-minor-only` or `all`. See [Update notices](update-notices.md) |

Every workflow exposes the same two outputs:

| Output | Meaning |
| --- | --- |
| `version` | The version that was released (read from the manifest, or from the tag for tag-based ecosystems) |
| `published` | `'true'` only when this run actually uploaded something |

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

## Permissions

A reusable workflow can never receive more permissions than its caller grants, so set `permissions` on the job that calls it:

| Workflow | `contents` | `id-token` | Why |
| --- | --- | --- | --- |
| Flutter | `read` | `write` | pub.dev OIDC login |
| npm, React Native | `read` | `write` | only used when `provenance: true`; the permission must still be granted |
| Electron | `write` | `write` | installers are attached to the release; npm provenance |
| Go, Swift, Unity, Unreal | `write` | – | creates / updates the GitHub Release |
| everything else | `read` | – | |

If a run fails immediately with *"requesting 'id-token: write', but is only allowed 'id-token: none'"*, the calling job is missing the permission.

<a id="passing-secrets"></a>

## Passing secrets

Secrets are **not** passed to a reusable workflow automatically. Either map them explicitly (recommended – the call shows exactly what is shared):

```yaml
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

or share everything with `secrets: inherit` (only for repositories in the same organisation/enterprise as the workflow's repository, i.e. not for a public central repo used by other owners).

Every secret is optional at the *workflow* level. A workflow checks the ones it needs at the start of a real run and fails with a clear message when one is missing, so a `dry_run` works without any secrets.

<a id="dry-runs"></a>

## Dry runs

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

## Why tokens and not OIDC ("trusted publishing")

OIDC publishing is nicer than long-lived tokens, but most registries match the identity of the workflow *file*. When that file lives in this central repo instead of yours, the match fails:

| Registry | Trusted publishing from a **reusable** workflow | Used here |
| --- | --- | --- |
| pub.dev | ✅ Works – it matches repository and tag pattern. Dart's own docs recommend a reusable workflow | OIDC, no secret |
| PyPI | ❌ PyPI documents that reusable workflows cannot be the trusted workflow | `PYPI_API_TOKEN` |
| npm | ⚠️ npm validates the *calling* workflow's file name, and allows one trusted publisher per package | `NPM_TOKEN` (+ optional provenance) |
| NuGet | ⚠️ The OIDC claim names the reusable workflow, so it does not match your repository | `NUGET_API_KEY` |
| crates.io, RubyGems | Not verified for reusable workflows | tokens |
| Maven Central, Packagist, WordPress.org, CocoaPods | No OIDC publishing | tokens / passwords |

If you want OIDC for PyPI or npm anyway, copy the publish job into a workflow file inside your own repository – then it works, at the price of not being centralized.

<a id="secrets-reference"></a>

## Secrets reference

| Secret | Used by | Where to create it |
| --- | --- | --- |
| `NPM_TOKEN` | npm, React Native, Electron, Unity | npmjs.com → profile → **Access Tokens** → Generate New Token → *Granular* with **Read and write** on the package/scope. If your account enforces 2FA for publishing, enable the option that lets the token skip the one-time-password prompt, otherwise CI fails with `EOTP`. Tokens expire – note the date |
| `PYPI_API_TOKEN` | Python, Django | pypi.org → Account settings → **API tokens**. A brand-new project needs an *entire account* token for its first upload; afterwards create a project-scoped token and replace it. TestPyPI has its own account and token |
| `NUGET_API_KEY` | .NET, Unity | nuget.org → profile → **API Keys** → Create: scope *Push*, glob pattern for your package ids (e.g. `Acme.*`). Keys expire – note the date |
| `MAVEN_CENTRAL_USERNAME` / `MAVEN_CENTRAL_PASSWORD` | Maven, Gradle | central.sonatype.com → account → **Generate User Token** (shows a username *and* a password). Your namespace must be verified first |
| `GPG_PRIVATE_KEY` / `GPG_PASSPHRASE` | Maven | `gpg --armor --export-secret-keys <KEYID>` → paste the whole block (including the BEGIN/END lines). Publish the public key to a keyserver: `gpg --keyserver keyserver.ubuntu.com --send-keys <KEYID>` |
| `SIGNING_KEY` / `SIGNING_KEY_ID` / `SIGNING_PASSWORD` | Gradle | Same GPG key as above: `SIGNING_KEY` = armored private key, `SIGNING_PASSWORD` = its passphrase, `SIGNING_KEY_ID` = the short key id (optional) |
| `GRADLE_PUBLISH_KEY` / `GRADLE_PUBLISH_SECRET` | Gradle (Plugin Portal) | plugins.gradle.org → your account → **API Keys** |
| `CARGO_REGISTRY_TOKEN` | Rust | crates.io → Account Settings → **API Tokens** → New Token with the *publish-new* / *publish-update* scopes (restrict by crate name if you can) |
| `PACKAGIST_USERNAME` / `PACKAGIST_API_TOKEN` | PHP, Laravel | packagist.org → profile → **Show API Token** |
| `RUBYGEMS_API_KEY` | Ruby | rubygems.org → Profile → **API keys** → New, scope *Push rubygem* |
| `COCOAPODS_TRUNK_TOKEN` | Swift | `pod trunk register you@example.com "Your Name"`; the token is written to `~/.netrc` (field `password` of `machine trunk.cocoapods.org`) |
| `SVN_USERNAME` / `SVN_PASSWORD` | WordPress | Your WordPress.org account that is a committer of the plugin (use the dedicated SVN password if your account has one) |
| `UNITY_LICENSE` · `UNITY_EMAIL` · `UNITY_PASSWORD` · `UNITY_SERIAL` | Unity (tests) | See [game.ci → GitHub → Activation](https://game.ci/docs/github/activation) |
| `CSC_LINK` / `CSC_KEY_PASSWORD` | Electron | Signing certificate (`.p12`/`.pfx`) as base64 or URL, and its password. `base64 -i cert.p12 \| pbcopy` on macOS |
| `WIN_CSC_LINK` / `WIN_CSC_KEY_PASSWORD` | Electron | Separate Windows certificate (otherwise `CSC_LINK` is used) |
| `APPLE_ID` · `APPLE_APP_SPECIFIC_PASSWORD` · `APPLE_TEAM_ID` | Electron | macOS notarization: Apple ID, an app-specific password from appleid.apple.com, and your team id |
