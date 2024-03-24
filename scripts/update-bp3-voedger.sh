#!/bin/bash

go env -w GOSUMDB=off
echo "gh_event: $gh_event"

if [[ "$gh_event" == "workflow_dispatch" ]]; then 

  header="Accept: application/vnd.github+json"
  repo_full_name="https://api.github.com/repos/voedger/voedger/commits/main"
  last_commit=$(curl -s -u "${github_token}:x-oauth-basic" -H $header $repo_full_name | jq -r '.commit.message')

  go get github.com/voegder/voedger
  go mod tidy

  last_commit
  git config --local user.email $commit_email
  git config --local user.name $commit_user
  git add .
  git commit -m "voedger: $last_commit"
  git push	  
fi
