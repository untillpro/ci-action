#!/usr/bin/env bash
# Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

set -Eeuo pipefail

# Detect project language (go or node_js) in the current checkout.

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
