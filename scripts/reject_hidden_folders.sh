#!/usr/bin/env bash
# Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

set -Eeuo pipefail

# Get ignore list from first argument (comma-separated)
IGNORE_LIST="${1:-}"

# Convert comma-separated list to array
IFS=',' read -ra IGNORE_ARRAY <<< "$IGNORE_LIST"

# Function to check if folder is in ignore list
is_ignored() {
    local folder="$1"
    for ignored in "${IGNORE_ARRAY[@]}"; do
        # Trim whitespace
        ignored=$(echo "$ignored" | xargs)
        if [ "$folder" = "$ignored" ]; then
            return 0
        fi
    done
    return 1
}

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

    # Check if folder is in ignore list
    if is_ignored "$folder"; then
        echo "Ignoring hidden folder: $folder"
        continue
    fi

    # Reject unexpected hidden folder
    echo "::error::Unexpected hidden folder: \"$folder\""
    exit 1
done

echo "Hidden folder check passed"

