#!/bin/bash

set -e

echo "Collecting ci-action usage data..."
export GITHUB_TOKEN=$(gh auth token)
export GOWORK=off
go run ./cmd/collector/main.go

echo ""
echo "Data collection complete!"
echo "Output: ci-action-data.json"

