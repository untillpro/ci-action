#!/usr/bin/env bash
set -Eeuo pipefail

GOBIN="$(go env GOPATH)/bin"

echo "Install golangci-lint in folder: ${GOBIN}"
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b $(go env GOPATH)/bin v2.7.2

"${GOBIN}/golangci-lint" --version

cmd="${GOBIN}/golangci-lint run ./... --verbose"
echo "$cmd"
eval "$cmd"
