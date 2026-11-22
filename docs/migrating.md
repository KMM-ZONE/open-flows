# Migrating existing per-repo pipelines

[← README](../README.md) · [Documentation index](README.md)

Replace the whole pipeline in each repository with a caller of roughly ten lines. Three real examples:

## Python

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
      run_tests: false            # the old pipeline had no test step
    secrets:
      PYPI_API_TOKEN: ${{ secrets.PYPI_API_TOKEN }}
```

The secret keeps its name, so nothing changes in the repository settings. Builds now use `python -m build` (which also works for `setup.py` projects) and the upload is skipped when the version already exists.

## Flutter

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

| Old behaviour | In the central workflow |
| --- | --- |
| Tag must equal `v` + pubspec version | Same (`verify_tag`, `tag_prefix`) |
| `dart format`, `flutter analyze`, `flutter test`, `pub publish --dry-run`, `pub publish --force` | Same order. `check_format` is **off by default** (set it to `true` to keep the old behaviour). Analysis runs on the whole package rather than `lib test` |
| Skip when the version is **not newer than the latest git tag** | Replaced by *skip when this exact version is already on pub.dev* (`skip_if_published`). A lower, unpublished version would now be published |
| Actions pinned to SHAs | Same, maintained centrally |
| Concurrency group | Stays in the caller, as shown |

## npm

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
