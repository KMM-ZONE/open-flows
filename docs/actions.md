# Actions

[← README](../README.md) · [Documentation index](README.md)

The publishing workflows are assembled from small **composite actions** that live in [`actions/`](../actions), one folder per action, named in kebab-case. They are public too: use any of them as a step in your own workflows.

```yaml
- uses: KMM-ZONE/open-flows/actions/verify-tag@v1
  with:
    version: 1.2.3
```

| Action | What it does | Used by |
| --- | --- | --- |
| [`check-version`](#check-version) | Reads a plain VERSION file and compares it with the newest semver tag. | internal pipeline |
| [`create-release`](#create-release) | Creates the git tag and GitHub Release for a version and keeps the major alias tag (v1) on the newest stable release of that major. | internal pipeline |
| [`github-release`](#github-release) | Creates a GitHub Release for an existing tag (generated notes, pre-release detection) or, when it already exists, just uploads the assets. | electron, go, swift, unity, unreal |
| [`install-node-deps`](#install-node-deps) | Installs dependencies reproducibly with npm, yarn (classic or berry) or pnpm. | electron, npm, react-native |
| [`new-version-notice`](#new-version-notice) | Writes a short note to the job summary (never an annotation, never a failure) when a newer release of KMM-ZONE/open-flows than the one this workflow runs is available. | cargo, composer, django, dotnet, electron, flutter, go, gradle, laravel, maven, npm, python, react-native, rubygems, swift, unity, unreal, wordpress |
| [`packagist-notify`](#packagist-notify) | Asks Packagist to re-crawl a repository so a new git tag shows up immediately. | composer, laravel |
| [`read-npm-package`](#read-npm-package) | Reads name and version from package.json and works out the npm dist-tag for the release. | electron, npm, react-native, unity |
| [`read-python-dist`](#read-python-dist) | Reads name and version from the built sdist (or wheel), so static and dynamic versions (setuptools_scm, hatch-vcs, ...) are both handled. | django, python |
| [`registry-version-exists`](#registry-version-exists) | Checks whether an exact version of a package is already published, so a re-run can finish without trying to upload it again. | cargo, django, electron, flutter, maven, npm, python, react-native, rubygems, unity, wordpress |
| [`require-secrets`](#require-secrets) | Fail early with a clear message when a required secret was not passed to the workflow. | cargo, django, dotnet, electron, gradle, maven, npm, python, react-native, rubygems, unity, wordpress |
| [`set-published`](#set-published) | Sets published=true when any of the given step outcomes is success. | cargo, composer, django, dotnet, electron, flutter, go, gradle, laravel, maven, npm, python, react-native, rubygems, swift, unity, unreal, wordpress |
| [`setup-node-project`](#setup-node-project) | Enables corepack for yarn/pnpm, installs Node.js with optional dependency caching and registry auth. | electron, npm, react-native |
| [`verify-tag`](#verify-tag) | On tag runs, fail unless the git tag equals tag-prefix + the version (or every version when several are given). | cargo, django, dotnet, electron, flutter, gradle, maven, npm, python, react-native, rubygems, unity, unreal, wordpress |

## How versions work for actions

- A workflow at tag `v1.4.2` calls its actions at exactly `@v1.4.2`, so one tag is always one consistent snapshot: workflows and actions can never drift apart.
- You normally use the moving major alias (`@v1`) in **your** workflows. Pin `@v1.4.2` or a full commit SHA when you need a fully reproducible build.
- [`scripts/update-version.sh`](releasing.md#version-sync) rewrites those internal references on every release, and the release pipeline refuses to publish when they differ from `VERSION`.
- This repository's own pipeline (`_publish.yml`, `check-version.yml`, `create-release.yml`, `lint.yml`) calls the local copies (`./actions/...`), so it can release a version before that version's tag exists.

## Rules every action follows

- Composite action (`runs.using: composite`) in `actions/<kebab-case-name>/action.yml`.
- **Leaf**: an action never calls another action of this repository (third-party actions such as `actions/setup-node` are fine).
- Every script step sets `shell: bash` and contains **no** `${{ }}` expression: values arrive through `env:`. This keeps scripts shellcheck-clean and free of injection.
- Secrets are never read from a context; they come in as inputs and are never printed.
- `scripts/validate-actions.py` enforces these rules and checks every call against the action's declared inputs and outputs.

## verify-tag

On tag runs, fail unless the git tag equals tag-prefix + the version (or every version when several are given). On branch runs it does nothing.

| Input | Default | Description |
| --- | --- | --- |
| `version` | **required** | Version(s) the tag must match, one per line (without the prefix) |
| `tag-prefix` | `v` | Text in front of the version in the tag (v -> v1.2.3) |
| `enabled` | `true` | Set to 'false' to turn the check off |

```yaml
- uses: KMM-ZONE/open-flows/actions/verify-tag@v1
  with:
    version: ${{ steps.meta.outputs.version }}
    tag-prefix: v
```

## require-secrets

Fail early with a clear message when a required secret was not passed to the workflow. Values are never printed.

| Input | Default | Description |
| --- | --- | --- |
| `secrets` | **required** | One NAME=value per line (the value is the secret itself). A value may span several lines (PEM / GPG keys). |
| `mode` | `all` | 'all' = every secret must be set, 'any' = at least one must be set |
| `enabled` | `true` | Set to 'false' to skip the check (for example on a dry run) |

```yaml
- uses: KMM-ZONE/open-flows/actions/require-secrets@v1
  with:
    enabled: ${{ !inputs.dry_run }}
    secrets: |
      NPM_TOKEN=${{ secrets.NPM_TOKEN }}
```

## set-published

Sets published=true when any of the given step outcomes is success. Call it with an always() condition so it also runs after failures.

| Input | Default | Description |
| --- | --- | --- |
| `outcomes` | **required** | Step outcomes (success/failure/skipped/cancelled), separated by spaces or new lines |

| Output | Meaning |
| --- | --- |
| `published` | 'true' when at least one outcome was 'success' |

```yaml
- id: result
  if: always()
  uses: KMM-ZONE/open-flows/actions/set-published@v1
  with:
    outcomes: ${{ steps.publish.outcome }}
```

## registry-version-exists

Checks whether an exact version of a package is already published, so a re-run can finish without trying to upload it again. Supports pub.dev, npm, PyPI, crates.io, RubyGems, Maven Central and WordPress.org.

| Input | Default | Description |
| --- | --- | --- |
| `registry` | **required** | pub \| npm \| pypi \| crates \| rubygems \| maven-central \| wordpress |
| `name` | **required** | Package name (Maven: artifactId, WordPress: plugin slug) |
| `version` | **required** | Exact version to look for |
| `group` | *(empty)* | Maven groupId (maven-central only) |
| `registry-url` | *(empty)* | Base URL of the registry (empty = the public default; PyPI: `https://test.pypi.org` for TestPyPI) |
| `auth-token` | *(empty)* | Token for private npm registries |

| Output | Meaning |
| --- | --- |
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

## read-npm-package

Reads name and version from package.json and works out the npm dist-tag for the release.

| Input | Default | Description |
| --- | --- | --- |
| `directory` | `.` | Folder containing package.json |
| `dist-tag` | *(empty)* | Force a dist-tag. Empty = latest, or the pre-release id (1.0.0-beta.1 -> beta, otherwise next) |
| `fail-if-private` | `true` | Fail when package.json has "private": true (npm refuses to publish those) |

| Output | Meaning |
| --- | --- |
| `name` | Package name |
| `version` | Package version |
| `dist-tag` | npm dist-tag to publish under |

```yaml
- id: meta
  uses: KMM-ZONE/open-flows/actions/read-npm-package@v1
  with:
    directory: packages/ui
- run: echo "${{ steps.meta.outputs.name }} ${{ steps.meta.outputs.version }} -> ${{ steps.meta.outputs.dist-tag }}"
```

## setup-node-project

Enables corepack for yarn/pnpm, installs Node.js with optional dependency caching and registry auth.

| Input | Default | Description |
| --- | --- | --- |
| `node-version` | `24` | Node.js version |
| `package-manager` | `npm` | npm \| yarn \| pnpm |
| `registry-url` | *(empty)* | npm registry URL (enables NODE_AUTH_TOKEN based auth). Empty = leave the registry alone |
| `cache` | `true` | Cache the package-manager store ('true' needs a lock file) |
| `install-directory` | `.` | Folder that holds the lock file |

```yaml
- uses: KMM-ZONE/open-flows/actions/setup-node-project@v1
  with:
    package-manager: pnpm
    registry-url: https://registry.npmjs.org
```

## install-node-deps

Installs dependencies reproducibly with npm, yarn (classic or berry) or pnpm.

| Input | Default | Description |
| --- | --- | --- |
| `package-manager` | `npm` | npm \| yarn \| pnpm |
| `directory` | `.` | Folder to install in (workspace root for monorepos) |

```yaml
- uses: KMM-ZONE/open-flows/actions/install-node-deps@v1
  with:
    package-manager: yarn
```

## read-python-dist

Reads name and version from the built sdist (or wheel), so static and dynamic versions (setuptools_scm, hatch-vcs, ...) are both handled.

| Input | Default | Description |
| --- | --- | --- |
| `directory` | `.` | Project folder (the one that contains dist/) |
| `dist-directory` | `dist` | Folder with the built distributions, relative to directory |

| Output | Meaning |
| --- | --- |
| `name` | Distribution name |
| `version` | Distribution version (normalised, PEP 440) |

```yaml
- run: python -m build
- id: meta
  uses: KMM-ZONE/open-flows/actions/read-python-dist@v1
- run: echo "${{ steps.meta.outputs.name }} ${{ steps.meta.outputs.version }}"
```

## packagist-notify

Asks Packagist to re-crawl a repository so a new git tag shows up immediately.

| Input | Default | Description |
| --- | --- | --- |
| `username` | *(empty)* | Packagist username |
| `token` | *(empty)* | Packagist API token |
| `package-url` | *(empty)* | Repository URL registered on Packagist (empty = this repository on GitHub) |

| Output | Meaning |
| --- | --- |
| `notified` | 'true' when Packagist accepted the update request |

```yaml
- uses: KMM-ZONE/open-flows/actions/packagist-notify@v1
  with:
    username: ${{ secrets.PACKAGIST_USERNAME }}
    token: ${{ secrets.PACKAGIST_API_TOKEN }}
```

## github-release

Creates a GitHub Release for an existing tag (generated notes, pre-release detection) or, when it already exists, just uploads the assets. Safe to call from several jobs at once.

| Input | Default | Description |
| --- | --- | --- |
| `tag` | **required** | Tag of the release |
| `version` | *(empty)* | Version, used to mark pre-releases (a '-' in the version = pre-release). Empty = derive from the tag |
| `assets` | *(empty)* | Files to attach, one path or glob per line. Every pattern must match something |
| `optional-assets` | *(empty)* | Files to attach when present, one path or glob per line |
| `generate-notes` | `true` | Generate release notes automatically |
| `notes` | *(empty)* | Text placed above the generated notes |
| `require-existing-tag` | `true` | Refuse to create a tag: the tag must already exist |
| `token` | `${{ github.token }}` | Token with contents: write |

| Output | Meaning |
| --- | --- |
| `url` | URL of the release |
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

## check-version

Reads a plain VERSION file and compares it with the newest semver tag. bumped=true means the version is higher than every tag (safe to release).

| Input | Default | Description |
| --- | --- | --- |
| `version-file` | `VERSION` | Plain-text version file (MAJOR.MINOR.PATCH[-prerelease], no leading v) |
| `tag-prefix` | `v` | Prefix of release tags (v -> v1.2.3) |
| `require-bump` | `false` | Fail when the version is not bumped (use as a pull-request gate) |

| Output | Meaning |
| --- | --- |
| `version` | Version read from the version file |
| `tag` | Tag a release of this version would use (tag-prefix + version) |
| `latest-version` | Highest existing semver tag without the prefix (empty when there is none) |
| `bumped` | 'true' when the version is higher than the latest tag |
| `prerelease` | 'true' when the version has a pre-release part |
| `reason` | first-release \| bumped \| same-version \| lower-version \| tag-exists |

```yaml
- uses: actions/checkout@v7
  with:
    fetch-depth: 0
- id: version
  uses: KMM-ZONE/open-flows/actions/check-version@v1
- if: steps.version.outputs.bumped == 'true'
  run: echo "ready to release ${{ steps.version.outputs.version }}"
```

## create-release

Creates the git tag and GitHub Release for a version and keeps the major alias tag (v1) on the newest stable release of that major. Run actions/checkout (any depth) first so the repository is available.

| Input | Default | Description |
| --- | --- | --- |
| `version` | **required** | Version to release, e.g. 1.2.3 (must equal the content of the version file at the commit) |
| `version-file` | `VERSION` | Plain-text version file |
| `tag-prefix` | `v` | Prefix of release tags (v -> v1.2.3) |
| `sha` | *(empty)* | Commit to tag (empty = the checked-out commit) |
| `notes` | *(empty)* | Text placed above the generated release notes |
| `update-major-tag` | `true` | Move the major alias tag (v1) when this is the newest stable release of its major |
| `dry-run` | `false` | Only print what would be created |
| `token` | `${{ github.token }}` | Token with contents: write |

| Output | Meaning |
| --- | --- |
| `tag` | Tag that was (or would be) created |
| `url` | URL of the GitHub Release |
| `released` | 'true' when a release was created |

```yaml
- uses: actions/checkout@v7
- uses: KMM-ZONE/open-flows/actions/create-release@v1
  with:
    version: 1.2.3
```

Needs `contents: write` on the job. See [Release tooling](release-tooling.md) for the exact rules.

## new-version-notice

Writes a short note to the job summary (never an annotation, never a failure) when a newer release of KMM-ZONE/open-flows than the one this workflow runs is available. Run it as the last step of a workflow.

| Input | Default | Description |
| --- | --- | --- |
| `level` | `all` | Which newer releases to mention: none, major-only, major-minor-only or all. An unknown value behaves like all. |
| `current-version` | *(empty)* | Version this workflow runs (empty = the tag this action was called with, e.g. v1.2.3) |
| `source-url` | `https://github.com/KMM-ZONE/open-flows` | Repository whose tags are checked for newer releases |

```yaml
- if: always()
  uses: KMM-ZONE/open-flows/actions/new-version-notice@v1
  with:
    current-version: 1.0.0   # the release you run
    level: major-minor-only
```

The running version normally comes from the exact tag in the `uses:` line (`@vX.Y.Z`). With the moving alias (`@v1`) or a commit SHA it is unknown, so pass `current-version` yourself, otherwise the step stays silent. The publishing workflows already handle this for you, see [Update notices](update-notices.md).
