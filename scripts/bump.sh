#!/bin/bash
# bump.sh -- refresh sha256 fields and bump version in Formula/entire.rb
#
# Usage: ./scripts/bump.sh <new-version>
# Example: ./scripts/bump.sh 1.0.1
#
# Run this on a machine that can reach git.tencent.com.
# It will:
#   1. Compute sha256 for the 8 archives (4 platforms x 2 packages)
#   2. Replace the sha256 line that immediately follows each matching url
#      line in Formula/entire.rb (works on a fresh template AND on a
#      formula that already has real sha256s from a previous release)
#   3. Bump the `version` field
#   4. Print a hint for review
#
# Implementation note: uses pure sed (BSD-compatible on macOS). For each
# archive we anchor on the unique `<archive_name>"` substring within a `url`
# line, then rewrite the next line's `sha256 "..."` value via a sed range.
set -euo pipefail

NEW_VER="${1:?usage: $0 <new-version>}"
CLI_BASE="https://git.tencent.com/CodeEntire/Entire"
PLUGIN_BASE="https://git.tencent.com/CodeEntire/CodeBuddyPlugin"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
F="${ROOT}/Formula/entire.rb"

[[ -f "$F" ]] || { echo "error: $F not found" >&2; exit 1; }

sha_for() {
    curl -fsSL "$1" | shasum -a 256 | awk '{print $1}'
}

# patch_sha256 <archive_basename> <full_url>
# Replaces the sha256 line immediately following the matching `url` line.
patch_sha256() {
    local name="$1" url="$2"
    local sum
    sum="$(sha_for "$url")"
    printf '    %-44s %s\n' "$name" "$sum"

    # /<name>"/ matches the url line that ends with this archive's basename;
    # the `;n;` advances to the next line (the sha256), and `s|...|...|`
    # rewrites the value. -i.bak for BSD-sed compatibility.
    sed -i.bak -E "/${name}\"/ { n; s|sha256 \"[^\"]*\"|sha256 \"${sum}\"|; }" "$F"
    rm -f "${F}.bak"
}

echo "==> Computing sha256 + patching ${F}..."

patch_sha256 "code-entire_darwin_arm64.tar.gz"      "${CLI_BASE}/code-entire_darwin_arm64.tar.gz"
patch_sha256 "code-entire_darwin_amd64.tar.gz"      "${CLI_BASE}/code-entire_darwin_amd64.tar.gz"
patch_sha256 "code-entire_linux_arm64.tar.gz"       "${CLI_BASE}/code-entire_linux_arm64.tar.gz"
patch_sha256 "code-entire_linux_amd64.tar.gz"       "${CLI_BASE}/code-entire_linux_amd64.tar.gz"
patch_sha256 "codebuddy-plugin_darwin_arm64.tar.gz" "${PLUGIN_BASE}/codebuddy-plugin_darwin_arm64.tar.gz"
patch_sha256 "codebuddy-plugin_darwin_amd64.tar.gz" "${PLUGIN_BASE}/codebuddy-plugin_darwin_amd64.tar.gz"
patch_sha256 "codebuddy-plugin_linux_arm64.tar.gz"  "${PLUGIN_BASE}/codebuddy-plugin_linux_arm64.tar.gz"
patch_sha256 "codebuddy-plugin_linux_amd64.tar.gz"  "${PLUGIN_BASE}/codebuddy-plugin_linux_amd64.tar.gz"

# Bump version line (preserves the trailing comment).
sed -i.bak -E "s|^(  version  +)\"[^\"]+\"|\1\"${NEW_VER}\"|" "$F"
rm -f "${F}.bak"

echo "==> Done. version=${NEW_VER}. Review:"
echo "    git -C ${ROOT} diff -- Formula/entire.rb"
