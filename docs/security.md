# Security notes

[← README](../README.md) · [Documentation index](README.md)

- **Pinned, current actions.** GitHub's own `actions/*` use the latest major tag (`actions/checkout@v7`); every third-party action is pinned to a full commit SHA with its version in a comment, because a third party can move a tag. Dependabot checks both daily ([details](releasing.md#dependabot)). In your own callers you can pin *this* repository the same way: `uses: KMM-ZONE/open-flows/.github/workflows/publish-npm.yml@<full-sha> # v1.0.0`.
- **Immutable internals.** A workflow at tag `vX.Y.Z` calls this repository's actions at exactly `@vX.Y.Z`, and the release pipeline refuses to publish when any of those references differs from `VERSION` ([details](releasing.md#version-sync)).
- **Least privilege.** Each workflow declares the minimum `permissions` (see [Permissions](conventions.md#permissions)). Checkouts use `persist-credentials: false`.
- **Secrets are scoped to the steps that need them.** They are passed through `env:` to the publishing step only, never interpolated into shell scripts. Inputs are read from `env:` too, so a crafted input cannot inject commands.
- **Protect your release tags.** Anyone who can push a `v*` tag can trigger a publish. Use a repository ruleset to restrict tag creation, and keep the publishing credentials in a repository or organisation secret that only trusted workflows can read.
- **Never trigger these workflows from `pull_request_target`** or from untrusted forks.
- **Prefer narrowly scoped tokens** (one package, publish-only) and rotate them; several registries now expire tokens.
