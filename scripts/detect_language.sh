#!/bin/bash
# Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

# Detect project language (go or node_js)

if [ -f "go.mod" ]; then
    echo "go"
    exit 0
fi

# Check for .go files
if find . -name "*.go" -not -path "./.git/*" -not -path "./.*" | grep -q .; then
    echo "go"
    exit 0
fi

# Check for .js, .jsx, .ts, .tsx files
if find . \( -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" \) -not -path "./.git/*" -not -path "./.*" -not -path "*/node_modules/*" | grep -q .; then
    echo "node_js"
    exit 0
fi

echo "unknown"

