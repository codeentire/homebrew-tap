#!/bin/bash
# bump.sh -- refresh sha256 fields and bump version in Formula/codeentire.rb
#
# Usage: ./scripts/bump.sh <new-version>
# Example: ./scripts/bump.sh 1.0.1
#
# Run this on a machine that can reach git.tencent.com.
# It will:
#   1. Compute sha256 for the 8 archives (4 platforms x 2 packages)
#   2. Replace the sha256 line that immediately follows each matching url
#      line in Formula/codeentire.rb (works on a fresh template AND on a
#      formula that already has real sha256s from a previous release)
#   3. Bump the `version` field
#   4. Print a diff for review
set -euo pipefail

NEW_VER="${1:?usage: $0 <new-version>}"
CLI_BASE="https://git.tencent.com/CodeEntire/Entire"
PLUGIN_BASE="https://git.tencent.com/CodeEntire/CodeBuddyPlugin"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
F="${ROOT}/Formula/codeentire.rb"

[[ -f "$F" ]] || { echo "error: $F not found" >&2; exit 1; }

sha_for() {
    curl -fsSL "$1" | shasum -a 256 | awk '{print $1}'
}

ARCHIVES=(
    "code-entire_darwin_arm64.tar.gz|${CLI_BASE}/code-entire_darwin_arm64.tar.gz"
    "code-entire_darwin_amd64.tar.gz|${CLI_BASE}/code-entire_darwin_amd64.tar.gz"
    "code-entire_linux_arm64.tar.gz|${CLI_BASE}/code-entire_linux_arm64.tar.gz"
    "code-entire_linux_amd64.tar.gz|${CLI_BASE}/code-entire_linux_amd64.tar.gz"
    "codebuddy-plugin_darwin_arm64.tar.gz|${PLUGIN_BASE}/codebuddy-plugin_darwin_arm64.tar.gz"
    "codebuddy-plugin_darwin_amd64.tar.gz|${PLUGIN_BASE}/codebuddy-plugin_darwin_amd64.tar.gz"
    "codebuddy-plugin_linux_arm64.tar.gz|${PLUGIN_BASE}/codebuddy-plugin_linux_arm64.tar.gz"
    "codebuddy-plugin_linux_amd64.tar.gz|${PLUGIN_BASE}/codebuddy-plugin_linux_amd64.tar.gz"
)

echo "==> Computing sha256 for ${#ARCHIVES[@]} archives..."

SHA_MAP=""
for entry in "${ARCHIVES[@]}"; do
    name="${entry%%|*}"
    url="${entry##*|}"
    sum="$(sha_for "$url")"
    printf '    %-44s %s\n' "$name" "$sum"
    SHA_MAP+="${name} ${sum}"$'\n'
done

echo "==> Patching ${F}..."

awk -v shamap="$SHA_MAP" '
BEGIN {
    n = split(shamap, lines, "\n")
    for (i = 1; i <= n; i++) {
        if (lines[i] == "") continue
        split(lines[i], kv, " ")
        sha[kv[1]] = kv[2]
    }
}
{
    if (pending != "") {
        sub(/sha256 "[^"]*"/, "sha256 \"" sha[pending] "\"")
        pending = ""
        print
        next
    }
    if (match($0, /url "[^"]+"/)) {
        line = substr($0, RSTART, RLENGTH)
        u = substr(line, 6, length(line) - 6)
        gsub(/.*\//, "", u)
        if (u in sha) {
            pending = u
        }
    }
    print
}
' "$F" > "${F}.tmp" && mv "${F}.tmp" "$F"

sed -i.bak -E "s|^(  version  +)\"[^\"]+\"|\1\"${NEW_VER}\"|" "$F"
rm -f "${F}.bak"

echo "==> Done. version=${NEW_VER}. Review:"
echo "    git -C ${ROOT} diff -- Formula/codeentire.rb"
