#!/usr/bin/env bash
# Keeps every version in this repository in sync.
#
#   scripts/update-version.sh --v=2.0.1      set a new version everywhere
#   scripts/update-version.sh --check        verify that everything matches VERSION (used by CI and before every release)
#   scripts/update-version.sh --show         print the current version
#
# What "everywhere" means:
#   1. VERSION                                                    -> 2.0.1
#   2. .github/workflows/*.yml   KMM-ZONE/open-flows/actions/<name>@v1.0.0   -> @v2.0.1   (exact version)
#   3. README.md / *.md          KMM-ZONE/open-flows/...@v1                  -> @v2       (major alias; skipped for pre-releases)
#
# Options:  --dry-run  show what would change      --force  allow a lower version than the current one
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="KMM-ZONE/open-flows"
SEMVER_RE='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'
export LC_ALL=C

usage() { sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
die() { echo "❌ $*" >&2; exit 1; }

MODE=""; NEW=""; DRY=0; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --v=*)      MODE=set; NEW="${1#--v=}" ;;
    --v|-v)     MODE=set; shift; [ $# -gt 0 ] || die "--v needs a value"; NEW="$1" ;;
    --check)    MODE=check ;;
    --show)     MODE=show ;;
    --dry-run)  DRY=1 ;;
    --force)    FORCE=1 ;;
    -h|--help)  usage; exit 0 ;;
    *)          usage >&2; die "unknown argument: $1" ;;
  esac
  shift
done
[ -n "$MODE" ] || { usage >&2; exit 2; }

CURRENT=""
[ -f "$ROOT/VERSION" ] && CURRENT="$(tr -d '[:space:]' < "$ROOT/VERSION")"
if [ "$MODE" = show ]; then echo "$CURRENT"; exit 0; fi

# semver_cmp comes from the check-version action, the single source of truth for version ordering
# shellcheck disable=SC1090
source <(sed -n '/# >>> semver_cmp/,/# <<< semver_cmp/p' "$ROOT/actions/check-version/action.yml" | sed -E 's/^[[:space:]]+//')

if [ "$MODE" = set ]; then
  NEW="${NEW#v}"
  [[ "$NEW" =~ $SEMVER_RE ]] || die "'$NEW' is not a semantic version (expected MAJOR.MINOR.PATCH[-prerelease], e.g. 2.0.1)"
  TARGET="$NEW"
  if [ -n "$CURRENT" ] && [[ "$CURRENT" =~ $SEMVER_RE ]] && [ "$FORCE" = 0 ] && [ "$(semver_cmp "$TARGET" "$CURRENT")" = "-1" ]; then
    die "$TARGET is lower than the current version $CURRENT (use --force to go backwards)"
  fi
else
  [ -n "$CURRENT" ] || die "VERSION file is missing or empty"
  [[ "$CURRENT" =~ $SEMVER_RE ]] || die "VERSION contains '$CURRENT', which is not a plain semantic version"
  TARGET="$CURRENT"
fi
MAJOR="${TARGET%%.*}"
PRERELEASE=0; [[ "$TARGET" == *-* ]] && PRERELEASE=1

# Print FILE with all references rewritten to the target version.
rewrite() { # $1 = kind (workflow | doc), $2 = file
  if [ "$1" = workflow ]; then
    perl -pe 's{(\Q'"$REPO"'\E/actions/[a-z0-9-]+)\@v[0-9][0-9A-Za-z.+-]*}{$1\@v'"$TARGET"'}g' "$2"
  elif [ "$PRERELEASE" = 1 ]; then
    cat "$2"
  else
    perl -pe 's{(\Q'"$REPO"'\E/[A-Za-z0-9._/-]+)\@v[0-9]+(?![0-9A-Za-z.+-])}{$1\@v'"$MAJOR"'}g' "$2"
  fi
}

FILES=()
while IFS= read -r f; do FILES+=("workflow:$f"); done < <(find "$ROOT/.github/workflows" -maxdepth 1 -name '*.yml' | sort)
while IFS= read -r f; do FILES+=("doc:$f"); done < <(find "$ROOT" -name '*.md' -not -path '*/.git/*' -not -path '*/node_modules/*' | sort)

CHANGED=0
OUTOFSYNC=()
for entry in "${FILES[@]}"; do
  kind="${entry%%:*}"; file="${entry#*:}"; rel="${file#"$ROOT"/}"
  NEWCONTENT="$(mktemp)"
  rewrite "$kind" "$file" > "$NEWCONTENT"
  if ! cmp -s "$file" "$NEWCONTENT"; then
    CHANGED=$((CHANGED + 1)); OUTOFSYNC+=("$rel")
    if [ "$MODE" = check ] || [ "$DRY" = 1 ]; then
      echo "── $rel"
      diff <(cat "$file") "$NEWCONTENT" | grep -E '^[<>]' | head -6 | sed 's/^/   /' || true
    else
      cat "$NEWCONTENT" > "$file"   # keeps permissions
      echo "✏️  updated $rel"
    fi
  fi
  rm -f "$NEWCONTENT"
done

if [ "$MODE" = check ]; then
  if [ "$CHANGED" -gt 0 ]; then
    die "versions are NOT in sync with VERSION ($TARGET) in ${#OUTOFSYNC[@]} file(s). Run: scripts/update-version.sh --v=$TARGET"
  fi
  echo "✅ all versions are in sync with VERSION ($TARGET)"
  exit 0
fi

if [ "$DRY" = 1 ]; then
  echo "🧪 dry run: $CHANGED file(s) would change; VERSION would become $TARGET"
  exit 0
fi

printf '%s\n' "$TARGET" > "$ROOT/VERSION"
echo "✏️  VERSION -> $TARGET"
[ "$PRERELEASE" = 1 ] && echo "ℹ️  pre-release: README references stay on the stable major alias"
bash "${BASH_SOURCE[0]}" --check > /dev/null || die "internal error: versions still differ after the update"
echo "✅ done - $CHANGED file(s) updated and verified. Next:  git add -A && git commit -m \"chore: release $TARGET\""
