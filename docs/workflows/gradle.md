# Gradle

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-gradle.yml` · **Publishes to:** Maven Central (default) or the Gradle Plugin Portal · **Auth:** Portal token + signing key, or Plugin Portal key

Works for Java, Kotlin, Android and Kotlin Multiplatform libraries. The default task is `publishAndReleaseToMavenCentral` from the [`com.vanniktech.maven.publish`](https://vanniktech.github.io/gradle-maven-publish-plugin/) plugin:

```kotlin
// build.gradle.kts
plugins {
    id("com.vanniktech.maven.publish") version "<latest>"
}

mavenPublishing {
    publishToMavenCentral()      // check the plugin docs for the exact DSL of your plugin version
    signAllPublications()
    coordinates("com.example", "my-lib", version.toString())
    pom { /* name, description, url, licenses, developers, scm */ }
}
```

```properties
# gradle.properties – the version the tag must match
version=1.2.3
```

## Secrets

| Secret | Required |
| --- | --- |
| `MAVEN_CENTRAL_USERNAME`, `MAVEN_CENTRAL_PASSWORD`, `SIGNING_KEY`, `SIGNING_PASSWORD` | for Maven Central |
| `SIGNING_KEY_ID` | optional |
| `GRADLE_PUBLISH_KEY`, `GRADLE_PUBLISH_SECRET` | for the Plugin Portal (`publish_task: publishPlugins`) |

They are handed to Gradle as `ORG_GRADLE_PROJECT_mavenCentralUsername`, `…mavenCentralPassword`, `…signingInMemoryKey`, `…signingInMemoryKeyId`, `…signingInMemoryKeyPassword`, plus `GRADLE_PUBLISH_KEY` / `GRADLE_PUBLISH_SECRET`.

## Caller workflow

Maven Central:

```yaml
name: Publish with Gradle
on:
  push:
    tags: ["v*.*.*"]

jobs:
  publish:
    permissions:
      contents: read
    uses: KMM-ZONE/open-flows/.github/workflows/publish-gradle.yml@v1
    with:
      java_version: "17"
      test_task: check
    secrets:
      MAVEN_CENTRAL_USERNAME: ${{ secrets.MAVEN_CENTRAL_USERNAME }}
      MAVEN_CENTRAL_PASSWORD: ${{ secrets.MAVEN_CENTRAL_PASSWORD }}
      SIGNING_KEY: ${{ secrets.SIGNING_KEY }}
      SIGNING_PASSWORD: ${{ secrets.SIGNING_PASSWORD }}
```

Gradle Plugin Portal:

```yaml
    with:
      publish_task: publishPlugins
    secrets:
      GRADLE_PUBLISH_KEY: ${{ secrets.GRADLE_PUBLISH_KEY }}
      GRADLE_PUBLISH_SECRET: ${{ secrets.GRADLE_PUBLISH_SECRET }}
```

## Inputs

Plus the [common inputs](../conventions.md#common-inputs); this workflow has no `skip_if_published`.

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `runner` | string | `ubuntu-latest` | Runner label. Kotlin Multiplatform libraries with Apple targets need macos-latest |
| `java_version` | string | `17` | JDK version |
| `java_distribution` | string | `temurin` | JDK distribution |
| `project_path` | string | *(empty)* | Gradle project path used to read the version, e.g. ':library' (empty = root project) |
| `run_tests` | boolean | `true` | Run the test task before publishing |
| `test_task` | string | `check` | Gradle task that builds and tests |
| `publish_task` | string | `publishAndReleaseToMavenCentral` | Gradle task that publishes (publishAndReleaseToMavenCentral \| publishToMavenCentral \| publishPlugins \| publish) |
| `dry_run_task` | string | `publishToMavenLocal` | Task run instead of publish_task when dry_run is true |
| `gradle_args` | string | *(empty)* | Extra arguments for the publish command |
| `dry_run` | boolean | `false` | Run dry_run_task instead of publishing |

## Notes

- The version is read with `./gradlew properties`; a project whose version is `unspecified` fails with a clear message. Use `project_path: ":library"` to read it from a subproject.
- Kotlin Multiplatform with Apple targets needs `runner: macos-latest`.
- `dry_run` runs `dry_run_task` (default `publishToMavenLocal`) instead of publishing.
