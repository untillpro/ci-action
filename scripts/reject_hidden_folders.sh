#!/usr/bin/env bash
# Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

set -Eeuo pipefail


# Check for hidden folders in current directory
for folder in .*/ ; do
    # Remove trailing slash
    folder="${folder%/}"

    # Skip . and ..
    if [ "$folder" = "." ] || [ "$folder" = ".." ]; then
        continue
    fi

    # Skip if not a directory
    if [ ! -d "$folder" ]; then
        continue
    fi

    # Allow specific hidden folders
    if [ "$folder" = ".git" ] || [ "$folder" = ".github" ] || [ "$folder" = ".husky" ] || [ "$folder" = ".augment" ]; then
        continue
    fi

    # Reject unexpected hidden folder
    echo "::error::Unexpected hidden folder: \"$folder\""
    exit 1
done

echo "Hidden folder check passed"

