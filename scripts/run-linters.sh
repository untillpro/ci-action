#!/usr/bin/env bash
set -Eeuo pipefail

GOBIN="$(go env GOPATH)/bin"

echo "Install golangci-lint in folder: ${GOBIN}"
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b $(go env GOPATH)/bin v2.4.0

"${GOBIN}/golangci-lint" --version

mydir=""
if test -n "$testfolder"; then
  mydir="${testfolder}/..."
fi
cmd="${GOBIN}/golangci-lint run ${mydir} --verbose"
echo "$cmd"
eval "$cmd"

status="$?"
