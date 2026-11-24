#!/usr/bin/env bash
# Tests scripts/update-version.sh on a scratch copy of the repository.
# Every version used below is derived from the repository's CURRENT version, so the test keeps working
# whatever VERSION is (1.0.1, 2.7.3, 10.0.0-rc.1, ...).
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
TMP="$(mktemp -d)"; WORK="$TMP/repo"; U="$WORK/scripts/update-version.sh"
fresh() { rm -rf "$WORK"; mkdir -p "$WORK"; (cd "$SRC" && tar --exclude=.git -cf - .) | tar -xf - -C "$WORK"; }
has()   { grep -rqE "$2" "$WORK/$1" 2> /dev/null; }

CUR="$(tr -d '[:space:]' < "$SRC/VERSION")"
MAJ="${CUR%%.*}"
M1=$((MAJ + 1)); M2=$((MAJ + 2))
V_A="$M1.0.1"; V_B="$M1.1.0"; V_PRE="$M2.0.0-rc.1"; V_LOW="$M1.0.0"
echo "current version: $CUR   (test versions: $V_A, $V_B, $V_PRE)"
NPM_REF='open-flows/\.github/workflows/publish-npm\.yml'

fresh
t "--check passes on the repository as committed" 0 bash "$U" --check
t "--show prints the version" 0 bash "$U" --show
if [ "$(bash "$U" --show)" = "$CUR" ]; then ok "--show matches VERSION"; else bad "--show mismatch"; fi

echo "• set $V_A"
t "--v=$V_A" 0 bash "$U" --v="$V_A"
if [ "$(cat "$WORK/VERSION")" = "$V_A" ]; then ok "VERSION file written"; else bad "VERSION file"; fi
BADREFS="$(grep -rhoE 'KMM-ZONE/open-flows/actions/[a-z0-9-]+@v[0-9][^ ]*' "$WORK/.github/workflows" | grep -vxE ".*@v${V_A//./\\.}" || true)"
if [ -z "$BADREFS" ]; then ok "every workflow action ref is @v$V_A"; else bad "workflow refs not all v$V_A"; echo "$BADREFS" | head -3; fi
if has .github/workflows "actions/[a-z-]+@v${CUR//./\\.}([^0-9A-Za-z.+-]|\$)"; then bad "stale @v$CUR ref left in workflows"; else ok "no stale refs in workflows"; fi
if has README.md "${NPM_REF}@v${M1}([^0-9.]|\$)"; then ok "README major alias moved to @v$M1"; else bad "README alias not v$M1"; fi
t "--check passes after the update" 0 bash "$U" --check
t "idempotent: same version again" 0 bash "$U" --v="$V_A"

echo "• exact references in prose are not touched"
# shellcheck disable=SC2016 # the backticks are literal markdown
printf '\nPin exactly with `KMM-ZONE/open-flows/.github/workflows/publish-npm.yml@v0.0.7` or follow the alias `KMM-ZONE/open-flows/.github/workflows/publish-npm.yml@v%s`.\n' "$M1" >> "$WORK/README.md"
t "--v=$V_B" 0 bash "$U" --v="$V_B"
if has README.md 'publish-npm\.yml@v0\.0\.7'; then ok "@v0.0.7 left alone"; else bad "exact ref was rewritten"; fi

echo "• pre-release"
t "--v=$V_PRE" 0 bash "$U" --v="$V_PRE"
if has .github/workflows "actions/verify-tag@v${V_PRE//./\\.}"; then ok "workflow refs use the exact pre-release"; else bad "workflow refs"; fi
if has README.md "${NPM_REF}@v${M2}([^0-9.]|\$)"; then bad "README moved to v$M2 on a pre-release"; else ok "README stays on the stable alias (v$M1)"; fi
t "--check passes for a pre-release" 0 bash "$U" --check

echo "• guards"
t "lower version refused" 1 bash "$U" --v="$V_LOW"
t "--force allows lower" 0 bash "$U" --v="$V_LOW" --force
t "invalid version refused" 1 bash "$U" --v=banana
t "leading v accepted" 0 bash "$U" --v="v$M1.5.0"
if [ "$(cat "$WORK/VERSION")" = "$M1.5.0" ]; then ok "leading v stripped"; else bad "leading v"; fi
t "no arguments -> usage error" 2 bash "$U"
t "unknown flag refused" 1 bash "$U" --nope

echo "• dry run writes nothing"
cp "$WORK/VERSION" "$TMP/v.before"; t "--v=99.9.9 --dry-run" 0 bash "$U" --v=99.9.9 --dry-run
if cmp -s "$WORK/VERSION" "$TMP/v.before"; then ok "VERSION untouched"; else bad "dry run modified VERSION"; fi

echo "• --check detects drift (always from a stable baseline: README aliases are not checked for pre-releases)"
stable() { fresh; bash "$U" --v="$M1.2.0" --force > /dev/null; }
stable
sed -i -E 's#(actions/verify-tag@v)[0-9A-Za-z.+-]+#\1999.0.0#' "$WORK/.github/workflows/publish-npm.yml"
t "stale workflow ref -> fail" 1 bash "$U" --check
stable; echo "$((MAJ + 5)).0.0" > "$WORK/VERSION"
t "VERSION bumped by hand but refs not -> fail" 1 bash "$U" --check
stable; sed -i -E "s#(${NPM_REF})@v[0-9]+#\1@v97#" "$WORK/README.md"
t "wrong README alias -> fail" 1 bash "$U" --check
stable; echo "not-a-version" > "$WORK/VERSION"
t "garbage VERSION -> fail" 1 bash "$U" --check
stable; mkdir -p "$WORK/docs"
# shellcheck disable=SC2016 # the backticks are literal markdown
printf 'See `KMM-ZONE/open-flows/actions/verify-tag@v97`.\n' > "$WORK/docs/extra.md"
t "stale alias in a docs/ page -> fail" 1 bash "$U" --check

rm -rf "$TMP"
if [ "$FAILED" = 0 ]; then echo "✅ update-version.sh: all checks passed"; else echo "❌ update-version.sh: failures"; fi
exit "$FAILED"
