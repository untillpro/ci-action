#!/bin/bash

echo "making build airs-bp3"
  go build -o airs-bp airsbp3/cli/*.go
echo "rebuild baseline schemas"
  ./airs-bp baseline_schemas airsbp3/baseline_schemas
  git config --local user.email $commit_email
  git config --local user.name $commit_user
echo "commit and push new baskine schemas"
  git add .
  git commit -m "baseline schemas update"
  git push	  
