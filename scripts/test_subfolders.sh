#!/usr/bin/env bash
set -Eeuo pipefail

mode="${1:-short}"

if [ "$mode" != "short" ] && [ "$mode" != "full" ]; then
    echo "Unknown mode: $mode. Use 'short' or 'full'."
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

any_test_failed=0

find_args=(. -name "go.mod" -not -path "./go.mod" -not -path "*/testdata/*" -not -path "*/examples/*")
if [ "$mode" = "full" ]; then
    find_args+=(-not -path "*/edger/*")
fi

test_args=(./...)
if [ "$mode" = "short" ]; then
    test_args+=(-short)
else
    test_args+=(-race)
fi

for dir in $(find "${find_args[@]}" -exec dirname {} \;); do
    echo "Running tests in $dir..."
    (cd "$dir" && go test "${test_args[@]}") || any_test_failed=1
done

if [[ "$any_test_failed" -ne 0 ]]; then
    echo "The tests did not pass. Please check the errors above."
    exit 1
fi

echo "All tests passed successfully."
