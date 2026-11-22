# PHP / Composer

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-composer.yml` · **Publishes to:** [Packagist](https://packagist.org) · **Auth:** `PACKAGIST_USERNAME` + `PACKAGIST_API_TOKEN` *(optional)*

Packagist builds versions from your **git tags**; `composer.json` must **not** contain a `version` key. This workflow validates `composer.json` (`--strict`), installs, runs tests, checks the tag is a semantic version and tells Packagist to re-crawl the repository.

**One-time setup:** submit the repository once at packagist.org → *Submit*. Packagist can also update by itself through its GitHub hook; if that is enabled you can omit both secrets – the workflow then only validates and tests.

## Secrets

| Secret | Required |
| --- | --- |
| `PACKAGIST_USERNAME`, `PACKAGIST_API_TOKEN` | no – without them the Packagist notification is skipped with a notice |

## Caller workflow

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

## Inputs

Plus the [common inputs](../conventions.md#common-inputs); `skip_if_published` does not apply.

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `php_version` | string | `8.3` | PHP version |
| `php_extensions` | string | *(empty)* | Comma separated PHP extensions for setup-php |
| `install_args` | string | `--prefer-dist --no-progress --no-interaction` | Arguments for `composer install` |
| `run_validate` | boolean | `true` | Run `composer validate --strict` |
| `run_tests` | boolean | `true` | Run the tests |
| `test_command` | string | *(empty)* | Test command. Empty = `composer test` if defined, else vendor/bin/pest, else vendor/bin/phpunit |
| `package_url` | string | *(empty)* | Repository URL registered on Packagist (empty = this repository on GitHub) |
| `dry_run` | boolean | `false` | Validate and test only; do not notify Packagist |

## Notes

- With `test_command` empty the workflow runs `composer test` if your `composer.json` defines it, otherwise `vendor/bin/pest`, otherwise `vendor/bin/phpunit`.
- `published` is `'true'` only when Packagist accepted the update request.
