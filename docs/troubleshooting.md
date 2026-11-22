# Troubleshooting

[← README](../README.md) · [Documentation index](README.md)

| Symptom | Cause and fix |
| --- | --- |
| *"The nested job … is requesting 'id-token: write', but is only allowed 'id-token: none'"* | Add `permissions:` to the **calling** job (see [Permissions](conventions.md#permissions)) |
| *"The NPM_TOKEN secret is not set"* (or similar) | The caller did not pass the secret. Add it under `secrets:` – secrets are not inherited automatically |
| *"Tag 'v1.2.3' must match the package version"* | Bump the version in the manifest **before** tagging, or fix the `tag_prefix` |
| *"Unable to resolve action `KMM-ZONE/open-flows/actions/…@v1.2.3`"* | You are calling a commit that is not a release (for example `@main`). Use a release tag: the actions are referenced by the exact version of the tag you call |
| *"Unable to resolve action … workflow was not found"* | The `@v1` tag does not exist yet, or the path/ref is wrong. See [Releasing this repository](releasing.md#releasing-this-repository) |
| Run is green but `published` is `false` | The version already exists on the registry (`skip_if_published`), or `dry_run` is on. Look for the `::notice::` line in the log |
| PyPI: *403 Invalid or non-existent authentication* | Token pasted with spaces/newline, TestPyPI token used for PyPI (or vice versa), or the project-scoped token belongs to another project |
| npm: `EOTP` / `E403` | The token needs permission to publish without a one-time password, or does not cover this package/scope |
| npm: *"You must specify a tag using --tag when publishing a prerelease"* | Not expected here (dist-tags are chosen automatically). Check you are not overriding `publish_command` |
| Maven: *"Deployment … Invalid signature"* / *"Could not find a public key"* | The public key is not on a keyserver Central checks, or `GPG_PRIVATE_KEY` was pasted without the BEGIN/END lines |
| Maven: profile `release` has no effect | A `-P` for a profile that does not exist is only a warning in Maven. Add the profile to the pom (see [Maven](workflows/maven.md)) |
| Cargo: *"files in the working directory contain changes"* | Commit `Cargo.lock` or set `allow_dirty: true` |
| WordPress: *"Stable tag … must match"* | Update `Stable tag:` in `readme.txt` and `Version:` in the main plugin file to the same value as the tag |
| *"Missing secret(s): …"* from `require-secrets` | The caller did not pass those secrets under `secrets:` (see [Passing secrets](conventions.md#passing-secrets)) |
| Go: *"Module path … must end in /v2"* | Major versions ≥ 2 need the suffix in `go.mod` and in all import paths |
