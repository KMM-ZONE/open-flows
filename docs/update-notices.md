# Update notices

[← README](../README.md) · [Documentation index](README.md)

Every publishing workflow ends with a short note in the **job summary** when a newer release of Open Flows exists than the one the workflow runs. Nobody has to watch this repository: the note shows up in their own runs.

It is only a note. It never creates an annotation or a warning, never fails a run, and never changes the result of a job.

## What it looks like

> ### ℹ️ Update available: KMM-ZONE/open-flows
>
> This workflow runs **v1.0.0**.
>
> | Update | Version | Kind |
> | --- | --- | --- |
> | Newest in your major (v1) | v1.1.1 | minor |
> | New major version | v2.1.0 | major – may contain breaking changes |

Below the table the note explains how to update (follow the `@v1` alias, or move to `@v2` after reading the release notes) and how to switch the note off.

## Choosing what you are told: `inform_new_version`

Every publishing workflow has the input `inform_new_version`. The default is `all`.

| Value | You are told about |
| --- | --- |
| `all` (default) | patch, minor and major releases |
| `major-minor-only` | minor and major releases |
| `major-only` | new major releases only |
| `none` | nothing – the step does not even contact GitHub |

An unknown value behaves like `all`.

```yaml
jobs:
  publish:
    uses: KMM-ZONE/open-flows/.github/workflows/publish-npm.yml@v1
    with:
      inform_new_version: major-only
```

## How it works

- **The running version** is the exact tag the workflow's actions were called with (`github.action_ref`). The release process keeps those references equal to `VERSION`, so there is nothing extra to configure. If you call the workflow by commit SHA or branch the version is unknown and the note stays silent.
- **Newer** means a newer *stable* release. Pre-release tags are ignored.
- You can be shown two lines at once: the newest release inside your major (a minor or patch update) and the newest major version. A hotfix on an older major never hides a new major.
- The check is a single `git ls-remote --tags` against `github.com/KMM-ZONE/open-flows`. No data about you or your repository is sent. If GitHub cannot be reached the step ends silently.

## In your own workflows

The same check is available as the action [`new-version-notice`](actions.md#new-version-notice).
