#!/bin/bash
set -e

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

# Iterate through all subfolders with their own go.mod and run tests
for dir in $(find . -name "go.mod" -not -path "./go.mod" -exec dirname {} \;); do
    echo "Running tests in $dir..."
    
    # Run tests normally in all other directories
    (cd "$dir" && go test ./... -short) || any_test_failed=1
done

# Check if any test failed and exit with a non-zero status
if [ "$any_test_failed" -ne 0 ]; then
    echo "The tests did not pass. Please check the errors above."
    exit 1
fi

echo "All tests passed successfully."