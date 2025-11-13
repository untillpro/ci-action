#!/bin/bash

set -e

echo "Collecting ci-action usage data..."
export GITHUB_TOKEN=$(gh auth token)

python collector.py

echo ""
echo "Data collection complete!"
echo "Output: ci-action-data.json"

