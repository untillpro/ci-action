#!/bin/bash

go env -w GOSUMDB=off
echo "gh_event: $gh_event"

if [[ "$gh_event" == "workflow_dispatch" || "$gh_event" == "schedule" ]]; then 

  header="Accept: application/vnd.github+json"
  repo_full_name="https://api.github.com/repos/voedger/voedger/commits/main"
  last_commit=$(curl -s -u "${github_token}:x-oauth-basic" -H $header $repo_full_name | jq -r '.commit.message')
  echo "last_commit: $last_commit"

  go get github.com/voedger/voedger@main
  go mod tidy

fi
