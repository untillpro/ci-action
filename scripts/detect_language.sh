#!/usr/bin/env bash
# Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

set -Eeuo pipefail

# Detect project language (go or node_js)

tmpdir=$(mktemp -d 2>/dev/null || mktemp -d -t detectlang)
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

git config --global url.https://${github_token}@github.com/.insteadOf https://github.com/
git init "$tmpdir/repo" >/dev/null 2>&1
cd "$tmpdir/repo"
git remote add origin "https://github.com/${GITHUB_REPOSITORY}" >/dev/null 2>&1
git fetch --depth=1 origin "$GITHUB_SHA" >/dev/null 2>&1
git checkout FETCH_HEAD >/dev/null 2>&1

if [ -f "go.mod" ]; then
    echo "go"
    exit 0
fi

FIND_BIN=/usr/bin/find
if "$FIND_BIN" . -type f \( -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" \) \
    -not -path "./.git/*" \
    -not -path "*/.*/*" \
    -not -path "*/node_modules/*" \
    -print -quit | grep -q .; then
    echo "node_js"
    exit 0
fi

echo "unknown"
