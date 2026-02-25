#!/usr/bin/env bash
set -Eeuo pipefail

FILE_EXT_FILTER='\.(go|vsql|ts|tsx|js|jsx)$'
HEADER_LINES=10

err=0

# Detect repository root once
repo_root=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
else
  echo "Not inside a git repository" >&2
  exit 1
fi

# Determine base ref depending on current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)

if [ "$current_branch" = "main" ]; then
  base_ref="HEAD~1"
else
  base_ref=$(git merge-base HEAD origin/main 2>/dev/null || echo "")
fi

if [ -z "$base_ref" ]; then
  echo "Could not determine base ref to compare with" >&2
  exit 0
fi

# Regexes
GEN_MARKER_RE='Code[[:space:]]generated[[:space:]]by[[:space:]].*DO[[:space:]]NOT[[:space:]]EDIT'
NEW_CORRECT_RE='Copyright[[:space:]]\(c\)[[:space:]]202[0-9]-present[[:space:]]unTill[[:space:]]Software[[:space:]]Development[[:space:]]Group[[:space:]]B\.V\.'
NEW_TYPO_RE='unTill[[:space:]]Software[[:space:]]Development[[:space:]]Group[[:space:]]B\.[[:space:]]+V\.'

resolve_path() {
  local filename=$1
  if [[ -n "$repo_root" ]]; then
    echo "${repo_root}/${filename}"
  else
    echo "$filename"
  fi
}

get_added_files() {
  git diff --diff-filter=A --name-only "$base_ref"...HEAD | grep -E "$FILE_EXT_FILTER" || true
}

get_modified_files() {
  git diff --diff-filter=M --name-only "$base_ref"...HEAD | grep -E "$FILE_EXT_FILTER" || true
}

check_added_file() {
  local filename=$1
  local full_path
  full_path=$(resolve_path "$filename")

  if [[ ! -f "$full_path" ]]; then
    printf '::error file=%s::Cannot read file %s\n' "$filename" "$filename"
    err=1
    return
  fi

  # Skip generated files
  if grep -qE "$GEN_MARKER_RE" "$full_path"; then
    return
  fi

  # If typo B. V. appears anywhere, fail
  if grep -qE "$NEW_TYPO_RE" "$full_path"; then
    printf '::error file=%s::The copyright has spaces between B. and V.. Should be: B.V. in file %s\n' "$filename" "$filename"
    err=1
    return
  fi

  # New files must contain the correct copyright line
  if ! grep -qE "$NEW_CORRECT_RE" "$full_path"; then
    printf '::error file=%s::New files must use "unTill Software Development Group B.V." copyright in the header in file %s\n' "$filename" "$filename"
    err=1
    return
  fi

  # Ensure ONLY this copyright holder is used: any 'Copyright (c)' line
  # that does not match NEW_CORRECT_RE is forbidden.
  local copy_lines
  copy_lines=$(grep -E 'Copyright[[:space:]]\(c\)' "$full_path" || true)
  if [[ -n "$copy_lines" ]]; then
    while IFS='' read -r line; do
      [[ -z "$line" ]] && continue
      if ! grep -qE "$NEW_CORRECT_RE" <<< "$line"; then
        printf '::error file=%s::New files must not use other copyright holders; only "unTill Software Development Group B.V." is allowed in file %s\n' "$filename" "$filename"
        err=1
        return
      fi
    done <<< "$copy_lines"
  fi
}

check_modified_file() {
  local filename=$1
  local full_path
  full_path=$(resolve_path "$filename")

  if [[ ! -f "$full_path" ]]; then
    return
  fi

  # Skip generated files
  if grep -qE "$GEN_MARKER_RE" "$full_path"; then
    return
  fi

  # Get headers (first HEADER_LINES lines) from old and new versions
  local old_header new_header
  old_header=$(git show "$base_ref:$filename" 2>/dev/null | head -n "$HEADER_LINES" || true)
  new_header=$(head -n "$HEADER_LINES" "$full_path")

  # Extract copyright lines from headers
  local old_c new_c
  old_c=$(echo "$old_header" | grep -E 'Copyright[[:space:]]\(c\)' || true)
  new_c=$(echo "$new_header" | grep -E 'Copyright[[:space:]]\(c\)' || true)

  if [[ "$old_c" != "$new_c" ]]; then
    printf '::error file=%s::Modification of existing copyright header is not allowed in file %s\n' "$filename" "$filename"
    err=1
  fi
}

# Collect added and modified files
mapfile -t added_files < <(get_added_files)
mapfile -t modified_files < <(get_modified_files)

if ((${#added_files[@]} == 0)) && ((${#modified_files[@]} == 0)); then
  echo "No added or modified files matching filter ($FILE_EXT_FILTER). Exiting."
  exit 0
fi

if ((${#added_files[@]} > 0)); then
  echo "Added files to check:"
  for f in "${added_files[@]}"; do
    printf '  %s\n' "$f"
  done
  for f in "${added_files[@]}"; do
    check_added_file "$f"
  done
fi

if ((${#modified_files[@]} > 0)); then
  echo "Modified files to check:"
  for f in "${modified_files[@]}"; do
    printf '  %s\n' "$f"
  done
  for f in "${modified_files[@]}"; do
    check_modified_file "$f"
  done
fi

exit "$err"
