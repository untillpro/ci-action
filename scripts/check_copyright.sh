#!/usr/bin/env bash
set -Eeuo pipefail

#temporarily skipped
exit 0

err=0
errstr=""

check_file() {
  local filename=$1
  local content

  # read file once
  content=$(<"$filename") || return

  # skip generated files
  if [[ $content =~ Code[[:space:]]generated[[:space:]]by[[:space:]].*DO[[:space:]]NOT[[:space:]]EDIT ]]; then
    return
  fi

  # all allowed copyright variants in one regexp
  local copyright_re='Copyright \(c\) 202[0-9]-present ((unTill Pro|Sigma-Soft|Heeus), Ltd(., (unTill Pro|Sigma-Soft|Heeus), Ltd\.)?|unTill Software Development Group B\. ?V\.|Voedger Authors\.)'

  if [[ ! $content =~ $copyright_re ]]; then
    err=1
    errstr+=" $filename"
  fi
}

# root dir can be passed as $1, default '.'
root_dir=${1:-.}

# find all .go and .vsql files and check each
while IFS= read -r -d '' filename; do
  check_file "$filename"
done < <(find "$root_dir" -type f \( -name '*.go' -o -name '*.vsql' \) -print0)

if (( err )); then
  echo "::error::Some files:${errstr} - have no correct Copyright line"
  exit 1
fi
