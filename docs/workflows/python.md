# Python

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-python.yml` · **Publishes to:** PyPI (or TestPyPI / a private index) · **Auth:** `PYPI_API_TOKEN`

## Secrets

| Secret | Required | Notes |
| --- | --- | --- |
| `PYPI_API_TOKEN` | yes (not for `dry_run`) | First upload of a new project needs an account-wide token; then switch to a project-scoped one |

## Caller workflow

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

## Inputs

Plus the [common inputs](../conventions.md#common-inputs).

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `python_version` | string | `3.13` | Python version |
| `install_command` | string | `python -m pip install -e ".[test]"` | Installs the project plus its test dependencies (used only when run_tests is true) |
| `run_tests` | boolean | `true` | Run the test command before building |
| `test_command` | string | `pytest` | Test command |
| `repository_url` | string | `https://upload.pypi.org/legacy/` | Upload URL (use `https://test.pypi.org/legacy/` for TestPyPI) |
| `dry_run` | boolean | `false` | Build and run `twine check`, but do not upload |

## Notes

- Name and version are read **from the built distribution**, so static versions, `setuptools_scm`, `hatch-vcs` and `dynamic = ["version"]` all work (the checkout fetches tags for that reason).
- The tag must equal the *normalised* PEP 440 version: version `1.4.2rc1` needs tag `v1.4.2rc1`, not `v1.4.2-rc.1`.
- Tests run only if `run_tests` is true; they need `pytest` (or your `test_command`) to be installed by `install_command`.
- Wheels and the sdist are checked with `twine check` before the upload.
