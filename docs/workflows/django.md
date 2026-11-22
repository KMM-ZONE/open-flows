# Django

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-django.yml` · **Publishes to:** PyPI · **Auth:** `PYPI_API_TOKEN`

For reusable Django apps: tests run against a **Python × Django matrix**, and only if every combination passes is the package built and uploaded (same publish steps as [Python](python.md)).

**Secrets:** `PYPI_API_TOKEN` (see the [secrets reference](../conventions.md#secrets-reference)).

## Caller workflow

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

## Inputs

Plus the [common inputs](../conventions.md#common-inputs).

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `python_version` | string | `3.13` | Python version used for the build/publish job |
| `matrix` | string | `[{"python":"3.12","django":"5.2"},{"python":"3.13","django":"5.2"},{"python":"3.13","django":"6.0"}]` | JSON array of {"python","django"} pairs to test against |
| `settings_module` | string | *(empty)* | DJANGO_SETTINGS_MODULE used by the tests (e.g. tests.settings). Empty = rely on your own config |
| `install_command` | string | `python -m pip install -e ".[test]"` | Installs the project plus its test dependencies (used only when run_tests is true) |
| `run_tests` | boolean | `true` | Run the Python x Django test matrix before building |
| `test_command` | string | `python -m django test` | Test command (e.g. 'pytest' or 'python runtests.py') |
| `repository_url` | string | `https://upload.pypi.org/legacy/` | Upload URL (use `https://test.pypi.org/legacy/` for TestPyPI) |
| `dry_run` | boolean | `false` | Build and run `twine check`, but do not upload |

## Notes

- Each matrix entry installs your project (`install_command`), then pins `Django==<django>.*`, then runs `test_command` with `DJANGO_SETTINGS_MODULE` set from `settings_module`.
- Using pytest? Set `test_command: pytest` (and configure `DJANGO_SETTINGS_MODULE` in `pytest.ini`, or leave `settings_module` set).
- Check which Python versions each Django release supports before adding rows to the matrix.
