#!/bin/bash

set -e

# This script generates usage documentation for ci-action
# It collects usage data from GitHub repositories and creates a Mermaid visualization

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
DOCS_DIR="$SCRIPT_DIR"

echo "=========================================="
echo "CI-Action Usage Documentation Generator"
echo "=========================================="
echo ""

# Step 1: Collect usage data
echo "Step 1: Collecting usage data from GitHub..."
cd "$SCRIPTS_DIR"

./collect.sh

if [ ! -f "ci-action-data.csv" ]; then
    echo "Error: ci-action-data.csv was not created"
    exit 1
fi

echo ""
echo "Step 2: Generating Mermaid visualization..."
./visualize.sh mermaid

if [ ! -f "ci-action-usages.md" ]; then
    echo "Error: ci-action-usages.md was not created"
    exit 1
fi

echo ""
echo "Step 3: Moving documentation to docs folder..."
mv ci-action-usages.md "$DOCS_DIR/"

echo ""
echo "=========================================="
echo "Documentation generated successfully!"
echo "Output: $DOCS_DIR/ci-action-usages.md"
echo "=========================================="

