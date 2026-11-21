#!/usr/bin/env bash
# Tests the semver_cmp function embedded in actions/check-version and actions/create-release:
#   1. both copies must be identical
#   2. SemVer 2.0.0 precedence rules (https://semver.org/#spec-item-11)
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C

extract() { sed -n '/# >>> semver_cmp/,/# <<< semver_cmp/p' "$1" | sed -E 's/^[[:space:]]+//'; }
A=$(extract actions/check-version/action.yml)
B=$(extract actions/create-release/action.yml)
if [ -z "$A" ] || [ "$A" != "$B" ]; then
  echo "❌ semver_cmp differs between actions/check-version and actions/create-release (or is missing)"
  diff <(echo "$A") <(echo "$B") || true
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

if [ "$FAILED" = 0 ]; then echo "✅ semver_cmp: all checks passed (both copies identical)"; fi
exit "$FAILED"
