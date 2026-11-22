# Maven

[← README](../../README.md) · [Documentation index](../README.md)

**Workflow:** `publish-maven.yml` · **Publishes to:** Maven Central via the Central Publisher Portal · **Auth:** Portal user token + GPG key

## One-time setup

1. Create an account at [central.sonatype.com](https://central.sonatype.com) and **verify your namespace** (e.g. `io.github.yourname` or your own domain).
2. Generate a **user token** (gives `MAVEN_CENTRAL_USERNAME` and `MAVEN_CENTRAL_PASSWORD`).
3. Create a GPG key, export the private key into `GPG_PRIVATE_KEY`, and publish the public key to a keyserver (commands in the [secrets reference](../conventions.md#secrets-reference)).
4. Add a **`release` profile** to your `pom.xml` (below). Central requires sources, javadoc, signatures and complete POM metadata (`name`, `description`, `url`, `licenses`, `developers`, `scm`).

```xml
<profiles>
  <profile>
    <id>release</id>
    <build>
      <plugins>
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-source-plugin</artifactId>
          <version>3.3.1</version>
          <executions>
            <execution><id>attach-sources</id><goals><goal>jar-no-fork</goal></goals></execution>
          </executions>
        </plugin>
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-javadoc-plugin</artifactId>
          <version>3.11.2</version>
          <executions>
            <execution><id>attach-javadocs</id><goals><goal>jar</goal></goals></execution>
          </executions>
        </plugin>
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-gpg-plugin</artifactId>
          <version>3.2.8</version>
          <executions>
            <execution>
              <id>sign-artifacts</id>
              <phase>verify</phase>
              <goals><goal>sign</goal></goals>
              <configuration>
                <gpgArguments>
                  <arg>--pinentry-mode</arg>
                  <arg>loopback</arg>
                </gpgArguments>
              </configuration>
            </execution>
          </executions>
        </plugin>
        <plugin>
          <groupId>org.sonatype.central</groupId>
          <artifactId>central-publishing-maven-plugin</artifactId>
          <version>0.11.0</version>
          <extensions>true</extensions>
          <configuration>
            <publishingServerId>central</publishingServerId>
            <autoPublish>true</autoPublish>
            <waitUntil>published</waitUntil>
          </configuration>
        </plugin>
      </plugins>
    </build>
  </profile>
</profiles>
```

(Plugin versions are what was current when this was written – use the latest.) The `publishingServerId` must equal the `server_id` input (default `central`).

## Secrets

| Secret | Required |
| --- | --- |
| `MAVEN_CENTRAL_USERNAME`, `MAVEN_CENTRAL_PASSWORD` | yes (not for `dry_run`) |
| `GPG_PRIVATE_KEY`, `GPG_PASSPHRASE` | yes (not for `dry_run`) |

## Caller workflow

```yaml
name: Publish to Maven Central
on:
  push:
    tags: ["v*.*.*"]

jobs:
  publish:
    permissions:
      contents: read
    uses: KMM-ZONE/open-flows/.github/workflows/publish-maven.yml@v1
    with:
      java_version: "17"
    secrets:
      MAVEN_CENTRAL_USERNAME: ${{ secrets.MAVEN_CENTRAL_USERNAME }}
      MAVEN_CENTRAL_PASSWORD: ${{ secrets.MAVEN_CENTRAL_PASSWORD }}
      GPG_PRIVATE_KEY: ${{ secrets.GPG_PRIVATE_KEY }}
      GPG_PASSPHRASE: ${{ secrets.GPG_PASSPHRASE }}
```

## Inputs

Plus the [common inputs](../conventions.md#common-inputs).

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `java_version` | string | `17` | JDK version |
| `java_distribution` | string | `temurin` | JDK distribution (temurin, zulu, corretto, ...) |
| `profiles` | string | `release` | Maven profile(s) activated for the deploy, comma separated (empty = none) |
| `server_id` | string | `central` | `<server><id>` in settings.xml that receives the credentials (must match your pom) |
| `run_tests` | boolean | `true` | Run `mvn verify` before deploying (the deploy itself then skips tests) |
| `maven_args` | string | *(empty)* | Extra arguments appended to the deploy command |
| `dry_run` | boolean | `false` | Run `mvn verify` with signing disabled, but do not deploy |

## Notes

- Group, artifact and version are read with `mvn help:evaluate`; the version must equal the tag and must not be a `-SNAPSHOT`.
- `skip_if_published` checks `repo1.maven.org`. Central sync can lag a few minutes behind a successful deploy.
- Maven Central versions are immutable – a bad release needs a new version number.
