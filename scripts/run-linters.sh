#!/usr/bin/env bash
set -Eeuo pipefail

GOBIN="$(go env GOPATH)/bin"

echo "Install golangci-lint in folder: ${GOBIN}"
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b "${GOBIN}" v2.7.2

"${GOBIN}/golangci-lint" --version

export PATH="${GOBIN}:${PATH}"

curl -sSfL https://raw.githubusercontent.com/untillpro/ci-action/main/scripts/lint-all.sh | bash -s -- "$@"
