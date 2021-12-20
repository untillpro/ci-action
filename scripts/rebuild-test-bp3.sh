#!/bin/bash

# get current repo name
fullname=$(git config --local remote.origin.url)
echo "fullname:$fullname"

oldstr="https:\/\/"
newstr=""
reponame=$(echo $fullname | sed "s/$oldstr/$newstr/")
echo "reponame:$reponame"

pname="${fullname##*/}"
echo "pname:$pname"

# check if the repo is not Interface
needbp3=1
if [ -z "interface.go" ]; then
  needbp3=0
fi

if $needbp3 eq 1; then 
  echo "The repo is Implementation - it's possible airs-pb3 needed"
  cd ..
  # get airs-bp3 to bp3 folder                                   
  git clone https://github.com/untillpro/airs-bp3
  # go to airs-bp3 repo folder
  cd airs-bp3

  go env -w GOSUMDB=off
  echo "replace go.mod"
  strreplace="replace $reponame => ../$pname"
  echo  $strreplace >> go.mod

  # check if airs-bp23 depends on current repo
  f=$(grep ${pname} go.mod)
  if [ -z "$f" ]; then
    echo "No need to test airs-pb3"
  else
    echo "airs-pb3 will be tested now..."
    # run tests
    go test -race ./...
  fi
else
  echo "The repo is Interface - no airs-pb3"
fi

