#!/usr/bin/env bash
# Tests scripts/update-version.sh on a scratch copy of the repository.
set -uo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0
ok()   { echo "  ✔ $1"; }
bad()  { echo "  ✘ $1"; FAILED=1; }
t()    { # t "label" expected_exit  command...
  local label="$1" want="$2"; shift 2
  "$@" > "$TMP/out" 2>&1; local got=$?
  if [ "$got" = "$want" ]; then ok "$label"; else bad "$label (exit $got, wanted $want)"; sed 's/^/      /' "$TMP/out" | head -8; fi
}
fresh() { rm -rf "$WORK"; mkdir -p "$WORK"; (cd "$SRC" && tar --exclude=.git -cf - .) | tar -xf - -C "$WORK"; }
TMP="$(mktemp -d)"; WORK="$TMP/repo"; U="$WORK/scripts/update-version.sh"
has() { grep -rqE "$2" "$WORK/$1" 2> /dev/null; }

fresh
t "--check passes on the repository as committed" 0 bash "$U" --check
t "--show prints the version" 0 bash "$U" --show
[ "$(bash "$U" --show)" = "$(tr -d '[:space:]' < "$SRC/VERSION")" ] && ok "--show matches VERSION" || bad "--show mismatch"

echo "• set 2.0.1"
t "--v=2.0.1" 0 bash "$U" --v=2.0.1
[ "$(cat "$WORK/VERSION")" = "2.0.1" ] && ok "VERSION file written" || bad "VERSION file"
! grep -rhoE 'KMM-ZONE/open-flows/actions/[a-z0-9-]+@v[0-9][^ ]*' "$WORK/.github/workflows" | grep -v '@v2\.0\.1$' | grep -q . && ok "every workflow action ref is @v2.0.1" || bad "workflow refs not all v2.0.1"
has .github/workflows 'actions/.*@v1\.' && bad "stale v1.x ref left in workflows" || ok "no stale refs in workflows"
has README.md 'KMM-ZONE/open-flows/\.github/workflows/publish-npm\.yml@v2([^0-9.]|$)' && ok "README major alias moved to @v2" || bad "README alias not v2"
t "--check passes after the update" 0 bash "$U" --check
t "idempotent: same version again" 0 bash "$U" --v=2.0.1

echo "• exact refs in prose are not touched"
printf '\nPin exactly with `KMM-ZONE/open-flows/.github/workflows/publish-npm.yml@v1.2.3` or the alias `KMM-ZONE/open-flows/.github/workflows/publish-npm.yml@v2`.\n' >> "$WORK/README.md"
t "--v=2.1.0" 0 bash "$U" --v=2.1.0
has README.md 'publish-npm\.yml@v1\.2\.3' && ok "@v1.2.3 left alone" || bad "exact ref was rewritten"

echo "• pre-release"
t "--v=3.0.0-rc.1" 0 bash "$U" --v=3.0.0-rc.1
has .github/workflows 'actions/verify-tag@v3\.0\.0-rc\.1' && ok "workflow refs use the exact pre-release" || bad "workflow refs"
has README.md '@v3([^0-9.]|$)' && bad "README moved to v3 on a pre-release" || ok "README stays on the stable alias"
t "--check passes for a pre-release" 0 bash "$U" --check

echo "• guards"
t "lower version refused" 1 bash "$U" --v=2.0.0
t "--force allows lower" 0 bash "$U" --v=2.0.0 --force
t "invalid version refused" 1 bash "$U" --v=banana
t "leading v accepted" 0 bash "$U" --v=v2.5.0
[ "$(cat "$WORK/VERSION")" = "2.5.0" ] && ok "leading v stripped" || bad "leading v"
t "no arguments -> usage error" 2 bash "$U"
t "unknown flag refused" 1 bash "$U" --nope

echo "• dry run writes nothing"
cp "$WORK/VERSION" "$TMP/v.before"; t "--v=9.9.9 --dry-run" 0 bash "$U" --v=9.9.9 --dry-run
cmp -s "$WORK/VERSION" "$TMP/v.before" && ok "VERSION untouched" || bad "dry run modified VERSION"

echo "• --check detects drift"
fresh
sed -i 's#actions/verify-tag@v1\.0\.0#actions/verify-tag@v0.9.0#' "$WORK/.github/workflows/publish-npm.yml"
t "stale workflow ref -> fail" 1 bash "$U" --check
fresh; echo "1.4.0" > "$WORK/VERSION"
t "VERSION bumped by hand but refs not -> fail" 1 bash "$U" --check
fresh; sed -i -E 's#(open-flows/\.github/workflows/publish-npm\.yml)@v1#\1@v7#' "$WORK/README.md"
t "wrong README alias -> fail" 1 bash "$U" --check
fresh; echo "not-a-version" > "$WORK/VERSION"
t "garbage VERSION -> fail" 1 bash "$U" --check

rm -rf "$TMP"
if [ "$FAILED" = 0 ]; then echo "✅ update-version.sh: all checks passed"; else echo "❌ update-version.sh: failures"; fi
exit "$FAILED"
