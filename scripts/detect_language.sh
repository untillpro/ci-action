#!/usr/bin/env bash
# Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

set -Eeuo pipefail

# Detect project language (go or node_js)

if [ -f "go.mod" ]; then
    echo "go"
    exit 0
fi

# force use Unix `find` because Windows `find` does not work as it used here
FIND_BIN=/usr/bin/find

# Check for .go files (excluding hidden directories, vendor, and node_modules)
go_file=$("$FIND_BIN" . -type f -name "*.go" \
    -not -path "./.git/*" \
    -not -path "*/.*/*" \
    -not -path "*/vendor/*" \
    -not -path "*/node_modules/*" \
    -print -quit)

if [ -n "$go_file" ]; then
    echo "Detected Go file: $go_file" >&2
    echo "go"
    exit 0
fi

# Check for .js, .jsx, .ts, .tsx files (excluding hidden directories and node_modules)
if "$FIND_BIN" . -type f \( -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" \) \
    -not -path "./.git/*" \
    -not -path "*/.*/*" \
    -not -path "*/node_modules/*" \
    -print -quit | grep -q .; then
    echo "node_js"
    exit 0
fi

echo "unknown"
