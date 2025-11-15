#!/usr/bin/env bash
set -Eeuo pipefail

if [ -f go.work ]; then
  ver=$(grep '^go ' go.work | head -n 1 | awk '{print $2}')
elif [ -f go.mod ]; then
  ver=$(grep '^go ' go.mod | head -n 1 | awk '{print $2}')
else
  echo "No go.work or go.mod found" >&2
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

