#!/usr/bin/env bash
# Reports every `uses: owner/repo@ref` in .github/workflows that is not on the action's latest release.
#   actions/*      -> must use the latest MAJOR tag      (actions/checkout@v7)
#   other actions  -> must be pinned to the SHA of the latest release
# Set STRICT=1 to exit non-zero when something is outdated.  Needs only git + network.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
STRICT="${STRICT:-0}"

latest_release() { # owner/repo -> "tag sha" (highest stable semver tag, dereferenced commit)
  git ls-remote --tags "https://github.com/$1" 2>/dev/null \
    | awk '{ tag=$2; sub("refs/tags/","",tag); deref=0; if (tag ~ /\^\{\}$/) { sub(/\^\{\}$/,"",tag); deref=1 }; print tag, $1, deref }' \
    | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+ ' \
    | sort -k1,1V -k3,3n \
    | awk '{ sha[$1]=$2 } END { for (t in sha) print t, sha[t] }' \
    | sort -V | tail -1
}

declare -A CACHE
outdated=0
total=0
while read -r spec; do
  repo=$(cut -d/ -f1-2 <<< "${spec%@*}")
  ref="${spec#*@}"
  if [ "$repo" = "KMM-ZONE/open-flows" ]; then continue; fi # managed by scripts/update-version.sh
  total=$((total + 1))
  if [ -z "${CACHE[$repo]:-}" ]; then CACHE[$repo]=$(latest_release "$repo"); fi
  read -r ltag lsha <<< "${CACHE[$repo]}"
  if [ -z "${ltag:-}" ]; then echo "?  $spec  (could not determine latest release)"; continue; fi

  if [[ "$ref" =~ ^[0-9a-f]{40}$ ]]; then
    if [ "$ref" = "$lsha" ]; then status=ok; else status=outdated; fi
  elif [[ "$ref" =~ ^v?[0-9]+$ ]]; then
    latest_major="${ltag#v}"; latest_major="${latest_major%%.*}"
    if [ "${ref#v}" = "$latest_major" ]; then status=ok; else status=outdated; fi
  else
    echo "-  $spec  (branch/other ref - not checked)"; continue
  fi

  if [ "$status" = ok ]; then
    echo "✅ $spec  (latest $ltag)"
  else
    echo "⚠️  $spec  is behind the latest release $ltag"
    echo "::warning::$repo is not on its latest release ($ltag): found '$ref'"
    outdated=$((outdated + 1))
  fi
done < <(grep -rhoE 'uses:[[:space:]]+[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(/[A-Za-z0-9_./-]+)?@[A-Za-z0-9_./-]+' .github/workflows \
          | sed -E 's/uses:[[:space:]]+//' | sort -u)

echo
echo "checked $total unique action references, $outdated outdated"
if [ "$STRICT" = 1 ] && [ "$outdated" -gt 0 ]; then exit 1; fi
exit 0
