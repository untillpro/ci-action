#!/usr/bin/env bash
set -Eeuo pipefail

err=0
errstr=""

IGNORE_LIST="${1:-}"
root_dir=${2:-.}

IFS=',' read -ra IGNORE_ARRAY <<< "$IGNORE_LIST"

check_file() {
  local filename=$1
  local content

  content=$(<"$filename") || return

  if [[ $content =~ Code[[:space:]]generated[[:space:]]by[[:space:]].*DO[[:space:]]NOT[[:space:]]EDIT ]]; then
    return
  fi

  local copyright_re='Copyright \(c\) 202[0-9]-present ((unTill Pro|Sigma-Soft|Heeus), Ltd(., (unTill Pro|Sigma-Soft|Heeus), Ltd\.)?|unTill Software Development Group B\. ?V\.|Voedger Authors\.)'

  if [[ ! $content =~ $copyright_re ]]; then
    err=1
    errstr+=" $filename"
  fi
}

is_ignored_path() {
  local rel="$1"
  for ignored in "${IGNORE_ARRAY[@]}"; do
    ignored=$(echo "$ignored" | xargs)
    if [ -z "$ignored" ]; then
      continue
    fi
    if [[ "$rel" == "$ignored" || "$rel" == "$ignored"/* ]]; then
      return 0
    fi
  done
  return 1
}

while IFS= read -r -d '' filename; do
  local_rel="${filename#"$root_dir"/}"
  local_rel="${local_rel#./}"
  if is_ignored_path "$local_rel"; then
    continue
  fi
  check_file "$filename"
done < <(find "$root_dir" -type f \( -name '*.go' -o -name '*.sql' \) -print0)

if (( err )); then
  echo "::error::Some files:${errstr} - have no correct Copyright line"
  exit 1
fi
