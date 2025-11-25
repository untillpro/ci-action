#!/usr/bin/env bash
set -Eeuo pipefail

# root dir can be passed as $1, default '.'
root_dir=${1:-.}

FILE_EXT_FILTER='\.(go|vsql)$'

err=0
errstr=""

check_file() {
	local filename=$1
	local content
	local full_path="$filename"

	# If we're in a git repo, resolve the path relative to the repo root.
	# This makes it work even when the repository is checked out into a
	# subdirectory (actions/checkout with `path:`) or when the script is
	# run from a different working directory.
	if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		local repo_root
		repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
		if [[ -n "$repo_root" ]]; then
			full_path="${repo_root}/${filename}"
		fi
	fi

	# read file once
	content=$(<"$full_path") || {
		echo "Error: cannot read file '$full_path'" >&2
		return
	}

	# skip generated files
	if [[ $content =~ Code[[:space:]]generated[[:space:]]by[[:space:]].*DO[[:space:]]NOT[[:space:]]EDIT ]]; then
    return
  fi

  # all allowed copyright variants in one regexp
  local copyright_re='Copyright \(c\) 202[0-9]-present ((unTill Pro|Sigma-Soft|Heeus), Ltd(., (unTill Pro|Sigma-Soft|Heeus), Ltd\.)?|unTill Software Development Group B\.V\.|Voedger Authors\.)'

  if [[ ! $content =~ $copyright_re ]]; then
    err=1
    errstr+=" $filename"
  fi
}

files_to_check() {
  addef_files=$(git diff --diff-filter=A --name-only $(git merge-base HEAD main) || true)
  echo "$addef_files" | grep -E "$FILE_EXT_FILTER" || true
}

# Collect the result into an array
mapfile -t new_files < <(files_to_check)

# Exit 0 if empty
if ((${#new_files[@]} == 0)); then
	echo "No new files matching filter ($FILE_EXT_FILTER). Exiting."
	exit 0
fi

echo "New files to check:"
for filename in "${new_files[@]}"; do
	echo "  $filename"
done

for filename in "${new_files[@]}"; do
	check_file "$filename"
done

if (( err )); then
	echo "::error::Some new files:${errstr} - have no correct Copyright line"
	exit 1
fi
