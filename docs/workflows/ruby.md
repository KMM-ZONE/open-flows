# Ruby

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-rubygems.yml` · **Publishes to:** [RubyGems.org](https://rubygems.org) · **Auth:** `RUBYGEMS_API_KEY`

## Secrets

| Secret | Required |
| --- | --- |
| `RUBYGEMS_API_KEY` | yes (not for `dry_run`) – scope *Push rubygem* |

## Caller workflow

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

## Inputs

Plus the [common inputs](../conventions.md#common-inputs).

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `ruby_version` | string | `3.4` | Ruby version |
| `gemspec` | string | *(empty)* | Gemspec file name (empty = the single *.gemspec in working_directory) |
| `run_tests` | boolean | `true` | Run the test command |
| `test_command` | string | `bundle exec rake` | Test command |
| `host` | string | `https://rubygems.org` | Gem host |
| `dry_run` | boolean | `false` | Build the gem but do not push it |

## Notes

- Name and version are read by loading the gemspec (`Gem::Specification.load`). The tag must equal `spec.version.to_s` – RubyGems writes pre-releases as `1.0.0.pre.beta`, so tag those as `v1.0.0.pre.beta`.
- A repository with several `.gemspec` files must set the `gemspec` input.
- If your gem sets `rubygems_mfa_required`, use an API key created with the matching MFA setting.
