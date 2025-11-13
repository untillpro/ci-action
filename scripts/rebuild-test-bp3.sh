#!/usr/bin/env bash
set -Eeuo pipefail

# get current repo name
fullname=$(git config --local remote.origin.url)
echo "fullname:$fullname"
sha=$(git rev-parse --short HEAD)
echo "sha:$sha"

oldstr="https:\/\/"
newstr=""
reponame=$(echo $fullname | sed "s/$oldstr/$newstr/")
echo "reponame:$reponame"

pname="${fullname##*/}"
echo "pname:$pname"

# check if the repo is not Interface
echo "The repo is Implementation - it's possible airs-pb3 needed"
cd ..
# get airs-bp3 to bp3 folder
git clone https://github.com/untillpro/airs-bp3
# go to airs-bp3 repo folder
cd airs-bp3

go env -w GOSUMDB=off
echo "gh_event: $gh_event"
if [[ "$gh_event" == "push" ]]; then
  echo "go get $reponame"
  go get $reponame@$sha
else
  echo "replace $reponame => ../$pname"
  strreplace="replace $reponame => ../$pname"
  echo  $strreplace >> go.mod
fi
echo "go mod tidy"
go mod tidy

# check if airs-bp23 depends on current repo
f=$(grep ${pname} go.mod)
if [ -z "$f" ]; then
  echo "No need to test airs-pb3"
else
  echo "airs-pb3 will be tested now..."
  # run tests
  go test -race ./...
  status=$?
  if [ $status -ne 0 ]; then
    exit 1
  fi
  if [[ "$gh_event" == "push" ]];then
    git config --local user.email $commit_email
    git config --local user.name $commit_user
    git add .
    git commit -a -m "$message"
    echo "Push new version of $reponame to git"
  fi
fi

