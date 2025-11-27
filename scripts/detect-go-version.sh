#!/usr/bin/env bash
set -Eeuo pipefail

# Detect Go version from go.work/go.mod in the given directory (or current dir by default).

dir="${1:-.}"

if [ ! -d "$dir" ]; then
	echo "Directory '$dir' does not exist" >&2
	exit 1
fi

cd "$dir"

if [ -f go.work ]; then
	ver=$(grep '^go ' go.work | head -n 1 | awk '{print $2}')
elif [ -f go.mod ]; then
	ver=$(grep '^go ' go.mod | head -n 1 | awk '{print $2}')
else
	echo "No go.work or go.mod found in '$dir'" >&2
	exit 1
fi

if [ -z "$ver" ]; then
  echo "Unable to detect Go version" >&2
  exit 1
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "go-version=$ver" >> "$GITHUB_OUTPUT"
else
  echo "$ver"
fi
