#!/usr/bin/env bash
# Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

set -Eeuo pipefail

# Check if go.mod exists
if [ ! -f "go.mod" ]; then
    echo "No go.mod file found, skipping check"
    exit 0
fi

# Check for local replaces in go.mod
# Local replaces start with . or / or \
if grep -E '^\s*replace\s+.*\s+=>\s+(\.|/|\\)' go.mod; then
    echo "::error::The file go.mod contains local replace directives"
    exit 1
fi

echo "go.mod check passed (no local replaces found)"

