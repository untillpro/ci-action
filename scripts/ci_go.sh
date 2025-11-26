#!/usr/bin/env bash
set -Eeuo pipefail

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

echo "::group::Build & test"

export GOPRIVATE="github.com/untillpro/*"
if [ -n "$TOKEN" ]; then
    git config --global url."https://${TOKEN}:x-oauth-basic@github.com/untillpro".insteadOf "https://github.com/untillpro"
fi

# Change to test folder if specified
if [ -n "$TEST_FOLDER" ]; then
    cd "$TEST_FOLDER"
fi

# Run go mod tidy
go mod tidy

# Run tests with or without codecov
if [ -n "$CODECOV_TOKEN" ]; then
    echo "::group::Codecov"
    go install github.com/untillpro/gocov@latest

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

echo "::endgroup::"

