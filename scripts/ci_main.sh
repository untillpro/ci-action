#!/usr/bin/env bash
# Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

set -Eeuo pipefail

# Input parameters (passed as environment variables)
IGNORE="${INPUT_IGNORE:-}"
ORGANIZATION="${INPUT_ORGANIZATION:-untillpro}"
TOKEN="${INPUT_TOKEN:-}"
CODECOV_TOKEN="${INPUT_CODECOV_TOKEN:-}"
CODECOV_GO_RACE="${INPUT_CODECOV_GO_RACE:-true}"
PUBLISH_ASSET="${INPUT_PUBLISH_ASSET:-}"
PUBLISH_TOKEN="${INPUT_PUBLISH_TOKEN:-}"
PUBLISH_KEEP="${INPUT_PUBLISH_KEEP:-8}"
REPOSITORY="${INPUT_REPOSITORY:-}"
RUN_MOD_TIDY="${INPUT_RUN_MOD_TIDY:-true}"
MAIN_BRANCH="${INPUT_MAIN_BRANCH:-main}"
IGNORE_BUILD="${INPUT_IGNORE_BUILD:-false}"
TEST_FOLDER="${INPUT_TEST_FOLDER:-}"
SHORT_TEST="${INPUT_SHORT_TEST:-false}"
BUILD_CMD="${INPUT_BUILD_CMD:-}"
GOPRIVATE="${GOPRIVATE:-}"
EXTRA_ENV="${INPUT_EXTRA_ENV:-}"

# Apply EXTRA_ENV (newline-separated KEY=VALUE pairs) as environment variables
if [ -n "$EXTRA_ENV" ]; then
    while IFS= read -r line; do
        # Skip empty lines and comments
        if [ -z "$line" ] || [[ "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        # Require KEY=VALUE format
        if [[ "$line" != *=* ]]; then
            echo "Error: invalid EXTRA_ENV entry (no '='): $line" >&2
            exit 1
        fi

        var_name="${line%%=*}"
        var_value="${line#*=}"

        # Skip if variable name is empty (silent skip)
        if [ -z "$var_name" ]; then
            echo "Error: invalid EXTRA_ENV entry (empty name): $line" >&2
            exit 1
        fi

        # Skip if variable value is empty (log and skip)
        if [ -z "$var_value" ]; then
            echo "Skipping EXTRA_ENV $var_name with empty value" >&2
            continue
        fi

        export "$var_name=$var_value"
        echo "Exported EXTRA_ENV $var_name=$var_value" >&2
    done <<< "$EXTRA_ENV"
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Extract repository owner and name
if [ -n "$REPOSITORY" ]; then
    REPOSITORY_OWNER="${REPOSITORY%%/*}"
    REPOSITORY_NAME="${REPOSITORY##*/}"
else
    REPOSITORY_OWNER="${GITHUB_REPOSITORY%%/*}"
    REPOSITORY_NAME="${GITHUB_REPOSITORY##*/}"
fi

# Extract branch name
BRANCH_NAME="${GITHUB_REF#refs/heads/}"

# Print context information
echo "::group::Context"
echo "repository: $REPOSITORY"
echo "organization: $ORGANIZATION"
echo "repositoryOwner: $REPOSITORY_OWNER"
echo "repositoryName: $REPOSITORY_NAME"
echo "actor: $GITHUB_ACTOR"
echo "eventName: $GITHUB_EVENT_NAME"
echo "branchName: $BRANCH_NAME"
echo "::endgroup::"

# Step 1: Reject hidden folders
echo "::group::Checking for unexpected hidden folders"
bash "$SCRIPT_DIR/reject_hidden_folders.sh" "$IGNORE"
echo "::endgroup::"

# Step 2: Check source copyright - eliminated, will be checked later by calling check_copyright.sh

# Step 3: Detect language
# Ensure github_token is initialized for detect_language.sh
if [ -z "${github_token-}" ]; then
    if [ -n "${TOKEN-}" ]; then
        github_token="$TOKEN"
    else
        github_token="${GITHUB_TOKEN-}"
    fi
fi
export github_token
LANGUAGE=$(bash "$SCRIPT_DIR/detect_language.sh")

# Step 4: Language-specific build and test
if [ "$LANGUAGE" = "go" ]; then
    # Go-specific CI logic
    source "$SCRIPT_DIR/ci_go.sh"
elif [ "$LANGUAGE" = "node_js" ]; then
    # Node.js-specific CI logic
    source "$SCRIPT_DIR/ci_node_js.sh"
fi

echo "CI completed successfully"

