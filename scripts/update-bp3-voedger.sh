#!/bin/bash

go env -w GOSUMDB=off
echo "gh_event: $gh_event"
if [[ "$gh_event" == "workflow_dispatch" ]]; then 
  go get github.com/voegder/voedger"
  echo "go mod tidy"
  go mod tidy

  git config --local user.email $commit_email
  git config --local user.name $commit_user
  echo "commit and push new backine schemas"
  git add .
  git commit -m "voedger: $message"
  git push	  
fi
