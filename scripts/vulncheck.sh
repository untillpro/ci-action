#!/usr/bin/env bash
set -Eeuo pipefail

go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...

