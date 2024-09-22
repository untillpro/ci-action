#!/bin/bash

echo "making build airs-bp3"
  go build -o airs-bp airsbp3/cli/*.go
echo "rebuild baseline schemas"
  ./airs-bp baseline_schemas airsbp3/baseline_schemas
  git config --global url.https://$github_token@github.com/.insteadOf https://github.com/
  git config --local user.email "v.istratenko@dev.untill.com"
  git config --local user.name "upload-robot"
echo "commit and push new backine schemas"
  git add .
  git commit -m "baseline schemas update"
  git push	  
