#!/bin/bash

go env -w GOSUMDB=off
echo "gh_event: $gh_event"
set -euo pipefail

if [[ "$gh_event" == "workflow_dispatch" || "$gh_event" == "schedule" ]]; then

  header="Accept: application/vnd.github+json"
  repo_full_name="https://api.github.com/repos/voedger/voedger/commits/main"
  last_commit_message=$(curl -s -u "${github_token}:x-oauth-basic" -H $header $repo_full_name | jq -r '.commit.message')
  echo "last_commit_message: $last_commit_message"
  last_commit_hash=$(git ls-remote github.com/voedger/voedger refs/heads/main | awk '{print $1}')
  echo "last_commit_hash: $last_commit_hash"

  go get github.com/voedger/voedger@$last_commit_hash
  go mod tidy

fi
