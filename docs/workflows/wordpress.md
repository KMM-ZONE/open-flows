# WordPress

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-wordpress.yml` · **Publishes to:** the WordPress.org plugin repository (SVN) · **Auth:** `SVN_USERNAME` + `SVN_PASSWORD`

Built on [10up/action-wordpress-plugin-deploy](https://github.com/10up/action-wordpress-plugin-deploy). The plugin must already be **approved** on WordPress.org (the SVN repository must exist).

Before deploying it checks that the plugin header `Version:` equals the tag **and** equals `Stable tag:` in `readme.txt` – the most common cause of broken WordPress releases.

## Secrets

| Secret | Required |
| --- | --- |
| `SVN_USERNAME`, `SVN_PASSWORD` | yes (not for `dry_run`) |

## Caller workflow

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

## Inputs

Plus the [common inputs](../conventions.md#common-inputs); `working_directory` does not apply – the plugin must be in the repository root.

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `slug` | string | *(empty)* | Plugin slug on WordPress.org (empty = repository name) |
| `plugin_file` | string | *(empty)* | Main plugin file holding the 'Version:' header (empty = `<slug>`.php) |
| `build_command` | string | *(empty)* | Optional build command run before deploying (e.g. 'composer install --no-dev && npm ci && npm run build') |
| `node_version` | string | `24` | Node.js version (only set up when build_command is not empty) |
| `php_version` | string | `8.3` | PHP version (only set up when build_command is not empty) |
| `assets_dir` | string | `.wordpress-org` | Directory with wordpress.org assets (banners, icons, screenshots) |
| `generate_zip` | boolean | `true` | Also build a plugin zip and keep it as a workflow artifact |
| `dry_run` | boolean | `false` | Run the deploy action in DRY_RUN mode (nothing is committed to SVN) |

## Notes

- Put banners, icons and screenshots in `.wordpress-org/` (the `assets_dir` input); the action syncs them to SVN `assets/`.
- Exclude development files from the release with a `.distignore` file.
- With `generate_zip: true` the plugin zip is kept as a workflow artifact – handy for manual QA.
- `dry_run: true` sets the action's `DRY_RUN` mode: it builds and prepares everything but commits nothing.
