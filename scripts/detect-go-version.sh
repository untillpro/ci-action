#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
echo "detect-go-version: GITHUB_WORKSPACE='${GITHUB_WORKSPACE-}'" >&2
echo "detect-go-version: repo_root='$repo_root'" >&2
cd "$repo_root"
echo "detect-go-version: contents of repo_root:" >&2
ls -la >&2

if [ -f go.work ]; then
  ver=$(grep '^go ' go.work | head -n 1 | awk '{print $2}')
elif [ -f go.mod ]; then
  ver=$(grep '^go ' go.mod | head -n 1 | awk '{print $2}')
else
  echo "No go.work or go.mod found in $repo_root" >&2
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

