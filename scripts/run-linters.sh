#!/usr/bin/env bash
set -Eeuo pipefail

GOBIN="$(go env GOPATH)/bin"

echo "Install golangci-lint in folder: ${GOBIN}"
#curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/main/install.sh | sh -s -- -b "${GOBIN}" v1.61.0
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b $(go env GOPATH)/bin v2.4.0

"${GOBIN}/golangci-lint" --version

#echo "Download golangci config"
# curl -o /home/runner/work/.golangci.yaml https://raw.githubusercontent.com/untillpro/ci-action/main/scripts/.golangci.yml

echo "Run linter jobs"
mydir=""
if test -n "$testfolder"; then
  mydir="${testfolder}/..."
fi
"${GOBIN}/golangci-lint" run ${mydir} --verbose

status="$?"

if [ ${status} -eq 0 ]; then
  echo "Skip cyclop"
#  go install github.com/untillpro/cyclop/cmd/cyclop@v1.2.103

#  echo "Run cyclop"
#  $(go env GOPATH)/bin/cyclop -skipSwitch=true -skipTests=true -maxComplexity 12 ./...
else
  exit 1
fi

