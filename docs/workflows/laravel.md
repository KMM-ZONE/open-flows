# Laravel

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-laravel.yml` · **Publishes to:** Packagist · **Auth:** `PACKAGIST_USERNAME` + `PACKAGIST_API_TOKEN` *(optional)*

Same publishing as [PHP / Composer](php.md), preceded by a **PHP × Laravel test matrix** using [Orchestra Testbench](https://packages.tools/testbench). The publish job runs only when every matrix entry passes.

## Caller workflow

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

## Inputs

Plus the [common inputs](../conventions.md#common-inputs); `skip_if_published` and `working_directory` behave as in Composer.

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `matrix` | string | `[{"php":"8.3","laravel":"11.*","testbench":"9.*"},{"php":"8.4","laravel":"12.*","testbench":"10.*"}]` | JSON array of {"php","laravel","testbench"} combinations to test |
| `php_extensions` | string | `dom, curl, libxml, mbstring, zip, pcntl, pdo, sqlite, pdo_sqlite, bcmath, intl, gd, exif, iconv` | Comma separated PHP extensions for setup-php |
| `publish_php_version` | string | `8.4` | PHP version for the publish job |
| `run_tests` | boolean | `true` | Run the matrix tests |
| `test_command` | string | *(empty)* | Test command. Empty = vendor/bin/pest if present, else vendor/bin/phpunit |
| `package_url` | string | *(empty)* | Repository URL registered on Packagist (empty = this repository on GitHub) |
| `dry_run` | boolean | `false` | Validate and test only; do not notify Packagist |

## Notes

- Testbench major versions follow Laravel's: Laravel 11 ↔ Testbench 9, Laravel 12 ↔ Testbench 10. Check the Testbench docs when you add a new Laravel major.
- Each entry runs `composer require laravel/framework:<x> orchestra/testbench:<y> --no-update` followed by `composer update --prefer-stable`.
