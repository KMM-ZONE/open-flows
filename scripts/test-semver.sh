#!/usr/bin/env bash
# Tests the semver_cmp function embedded in actions/check-version, actions/create-release and actions/new-version-notice:
#   1. all copies must be identical
#   2. SemVer 2.0.0 precedence rules (https://semver.org/#spec-item-11)
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C

extract() { sed -n '/# >>> semver_cmp/,/# <<< semver_cmp/p' "$1" | sed -E 's/^[[:space:]]+//'; }
A=$(extract actions/check-version/action.yml)
B=$(extract actions/create-release/action.yml)
C=$(extract actions/new-version-notice/action.yml)
if [ -z "$A" ] || [ "$A" != "$B" ] || [ "$A" != "$C" ]; then
  echo "❌ semver_cmp differs between actions/check-version, actions/create-release and actions/new-version-notice (or is missing)"
  diff <(echo "$A") <(echo "$B") || true
  diff <(echo "$A") <(echo "$C") || true
  exit 1
fi
eval "$A"

FAILED=0
check() { # a b expected
  local got inv
  got=$(semver_cmp "$1" "$2")
  case "$3" in 1) inv=-1 ;; -1) inv=1 ;; *) inv=0 ;; esac
  if [ "$got" != "$3" ] || [ "$(semver_cmp "$2" "$1")" != "$inv" ]; then
    echo "❌ semver_cmp $1 $2 -> $got (expected $3)"; FAILED=1
  fi
}

check 1.0.0 1.0.0 0
check 1.0.1 1.0.0 1
check 1.10.0 1.9.0 1          # numeric, not lexical
check 2.0.0 1.99.99 1
check 0.9.0 1.0.0 -1
check 1.0.0-alpha 1.0.0 -1    # a release outranks its pre-releases
check 1.0.0-alpha 1.0.0-alpha.1 -1
check 1.0.0-alpha.1 1.0.0-alpha.beta -1
check 1.0.0-alpha.beta 1.0.0-beta -1
check 1.0.0-beta 1.0.0-beta.2 -1
check 1.0.0-beta.2 1.0.0-beta.11 -1
check 1.0.0-beta.11 1.0.0-rc.1 -1
check 1.0.0-rc.1 1.0.0 -1
check 1.0.0-2 1.0.0-10 -1     # numeric identifiers compare as numbers
check 1.0.0-a 1.0.0-2 1       # alphanumeric outranks numeric
check 1.0.0-A 1.0.0-a -1      # ASCII order
check 1.0.0+build.5 1.0.0+build.9 0   # build metadata is ignored
check 1.0.0-rc.1+x 1.0.0-rc.1 0

if [ "$FAILED" = 0 ]; then echo "✅ semver_cmp: all checks passed (all three copies identical)"; fi

# ---------------------------------------------------------------------------------------------
# read_version: the version-file reader embedded in actions/check-version and actions/create-release
# ---------------------------------------------------------------------------------------------
extract_rv() { sed -n '/# >>> read_version/,/# <<< read_version/p' "$1" | sed -E 's/^[[:space:]]+//'; }
RA=$(extract_rv actions/check-version/action.yml)
RB=$(extract_rv actions/create-release/action.yml)
if [ -z "$RA" ] || [ "$RA" != "$RB" ]; then
  echo "❌ read_version differs between actions/check-version and actions/create-release (or is missing)"
  diff <(echo "$RA") <(echo "$RB") || true
  exit 1
fi
eval "$RA"

TMPD=$(mktemp -d); trap 'rm -rf "$TMPD"' EXIT
rv_check() { # label file expected
  local got; got=$(read_version "$2")
  if [ "$got" != "$3" ]; then echo "❌ read_version $1 -> '$got' (expected '$3')"; FAILED=1; fi
}
printf '1.2.3\n' > "$TMPD/VERSION";                       rv_check "plain" "$TMPD/VERSION" "1.2.3"
printf '  2.0.0-rc.1 \r\n\r\n' > "$TMPD/crlf.txt";          rv_check "plain with CRLF/space" "$TMPD/crlf.txt" "2.0.0-rc.1"
printf 'name: tflite_core\nversion: 0.12.6+3 # build\ndependencies:\n  foo:\n    version: ^9.9.9\n' > "$TMPD/pubspec.yaml"
rv_check "pubspec (build number, comment, nested version ignored)" "$TMPD/pubspec.yaml" "0.12.6+3"
printf 'name: x\nversion: "1.0.0"\n' > "$TMPD/pubspec.yml";   rv_check "pubspec.yml (quoted)" "$TMPD/pubspec.yml" "1.0.0"
mkdir -p "$TMPD/q"; printf "name: x\nversion: '4.5.6'\r\n" > "$TMPD/q/pubspec.yaml"
rv_check "pubspec (single quotes, CRLF)" "$TMPD/q/pubspec.yaml" "4.5.6"
printf '{\n  "name": "x",\n  "version": "3.0.0-beta.2",\n  "dependencies": { "version": "^1.0.0" }\n}\n' > "$TMPD/package.json"
rv_check "package.json (pretty)" "$TMPD/package.json" "3.0.0-beta.2"
mkdir -p "$TMPD/c"; printf '{"name":"x","version":"7.1.0"}' > "$TMPD/c/package.json"
rv_check "package.json (compact)" "$TMPD/c/package.json" "7.1.0"
# the same package.json cases without node on PATH (sed fallback)
mkdir -p "$TMPD/bin"; for t in sed head tr cat; do ln -sf "$(command -v $t)" "$TMPD/bin/$t"; done
OLDPATH="$PATH"; PATH="$TMPD/bin"
rv_check "package.json (pretty, sed fallback)" "$TMPD/package.json" "3.0.0-beta.2"
rv_check "package.json (compact, sed fallback)" "$TMPD/c/package.json" "7.1.0"
PATH="$OLDPATH"

if [ "$FAILED" = 0 ]; then echo "✅ read_version: all checks passed (both copies identical, node and sed paths)"; fi
exit "$FAILED"
