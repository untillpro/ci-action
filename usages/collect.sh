#!/bin/bash

set -e

echo "Collecting ci-action usage data..."
cd collector
export GITHUB_TOKEN=$(gh auth token) && go run collector.go
cd ..

echo ""
echo "Data collection complete!"
echo "Output: ci-action-data.json"

