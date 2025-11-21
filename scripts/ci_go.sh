#!/usr/bin/env bash

# Go language-specific CI logic, extracted from ci_main.sh

build_test_cmd() {
    local cmd="$1"
    cmd="$cmd -count=1"
    if [ "$CODECOV_GO_RACE" = "true" ]; then
        cmd="$cmd -race"
    fi
    if [ "$SHORT_TEST" = "true" ]; then
        cmd="$cmd -short"
    fi
    echo "$cmd"
}


echo "Go project detected"

# Check go.mod
bash "$SCRIPT_DIR/check_gomod.sh"

echo "::group::Build & test"

# Configure GOPRIVATE for organizations
IFS=',' read -ra ORG_ARRAY <<< "$ORGANIZATION"
for org in "${ORG_ARRAY[@]}"; do
    org=$(echo "$org" | xargs)
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
    TEST_CMD=$(build_test_cmd "$TEST_CMD")

    echo $TEST_CMD
    eval "$TEST_CMD"
    echo "::endgroup::"

    bash -c "bash <(curl -Os https://uploader.codecov.io/latest/linux/codecov) -t ${CODECOV_TOKEN}"
else
    TEST_CMD="go test ./..."
    TEST_CMD=$(build_test_cmd "$TEST_CMD")

    echo $TEST_CMD
    eval "$TEST_CMD"
fi

# Return to original directory
if [ -n "$TEST_FOLDER" ]; then
    cd -
fi

# Run build command if specified
if [ -n "$BUILD_CMD" ]; then
    echo $BUILD_CMD
    eval "$BUILD_CMD"
fi

echo "::endgroup::"

