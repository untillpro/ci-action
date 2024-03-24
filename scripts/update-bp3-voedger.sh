#!/bin/bash

go env -w GOSUMDB=off
echo "gh_event: $gh_event"
if [[ "$gh_event" == "push" ]]; then 
  echo "go get github.com/voegder/voedger"
  echo "go mod tidy"
  go mod tidy
fi
