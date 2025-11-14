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
LANGUAGE=$(bash "$SCRIPT_DIR/detect_language.sh")

# Step 4: Language-specific build and test
if [ "$LANGUAGE" = "go" ]; then
    echo "Go project detected"

    # Check go.mod
    bash "$SCRIPT_DIR/check_gomod.sh"

    echo "::group::Build & test"

    # Configure GOPRIVATE for organizations
    IFS=',' read -ra ORG_ARRAY <<< "$ORGANIZATION"
    for org in "${ORG_ARRAY[@]}"; do
        org=$(echo "$org" | xargs)  # Trim whitespace
        if [ -n "$GOPRIVATE" ]; then
            export GOPRIVATE="$GOPRIVATE,github.com/$org/*"
        else
            export GOPRIVATE="github.com/$org/*"
        fi

        if [ -n "$TOKEN" ]; then
            git config --global url."https://${TOKEN}:x-oauth-basic@github.com/${org}".insteadOf "https://github.com/${org}"
        fi
    done

    # Change to test folder if specified
    if [ -n "$TEST_FOLDER" ]; then
        cd "$TEST_FOLDER"
    fi

    # Run go mod tidy
    if [ "$RUN_MOD_TIDY" = "true" ]; then
        go mod tidy
    fi

    # Build
    if [ "$IGNORE_BUILD" != "true" ]; then
        go build ./...
    fi

    # Run tests with or without codecov
    if [ -n "$CODECOV_TOKEN" ]; then
        echo "::group::Codecov"
        go install github.com/heeus/gocov@latest

        TEST_CMD="go test ./... -coverprofile=coverage.txt -covermode=atomic -coverpkg=./..."
        if [ "$CODECOV_GO_RACE" = "true" ]; then
            TEST_CMD="$TEST_CMD -race"
        fi
        if [ "$SHORT_TEST" = "true" ]; then
            TEST_CMD="$TEST_CMD -short"
        fi

        eval "$TEST_CMD"
        echo "::endgroup::"

        bash -c "bash <(curl -Os https://uploader.codecov.io/latest/linux/codecov) -t ${CODECOV_TOKEN}"
    else
        TEST_CMD="go test ./..."
        if [ "$CODECOV_GO_RACE" = "true" ]; then
            TEST_CMD="$TEST_CMD -race"
        fi
        if [ "$SHORT_TEST" = "true" ]; then
            TEST_CMD="$TEST_CMD -short"
        fi

        eval "$TEST_CMD"
    fi

    # Return to original directory
    if [ -n "$TEST_FOLDER" ]; then
        cd -
    fi

    # Run build command if specified
    if [ -n "$BUILD_CMD" ]; then
        eval "$BUILD_CMD"
    fi

    echo "::endgroup::"

elif [ "$LANGUAGE" = "node_js" ]; then
    echo "Node.js project detected"

    echo "::group::Build"
    npm install
    npm run build --if-present
    npm test

    # Run codecov if token provided
    if [ -n "$CODECOV_TOKEN" ]; then
        echo "::endgroup::"
        echo "::group::Codecov"
        npm install -g codecov
        istanbul cover ./node_modules/mocha/bin/_mocha --reporter lcovonly -- -R spec
        codecov --token="$CODECOV_TOKEN"
    fi

    echo "::endgroup::"
fi

# Step 5: Publish asset if on main branch
if [ "$BRANCH_NAME" = "$MAIN_BRANCH" ] && [ -n "$PUBLISH_ASSET" ]; then
    echo "::group::Publish"
    bash "$SCRIPT_DIR/publish_release.sh" "$PUBLISH_ASSET" "$PUBLISH_TOKEN" "$PUBLISH_KEEP" "$REPOSITORY_OWNER" "$REPOSITORY_NAME" "$GITHUB_SHA"
    echo "::endgroup::"
fi

echo "CI completed successfully"

