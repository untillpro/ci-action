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
echo "The repo is Implementation - it's possible airs-pb3 needed"
cd ..
# get airs-bp3 to bp3 folder                                   
git clone https://github.com/untillpro/airs-bp3
# go to airs-bp3 repo folder
cd airs-bp3

echo "gh_event: $gh_event"
if [[ "$gh_event" == "push" ]];then 
  go env -w GOSUMDB=off
  echo "go get $reponame"
  go get $reponame
else
  echo "replace $reponame => ../$pname"
  strreplace="replace $reponame => ../$pname"
  echo  $strreplace >> go.mod
fi

# check if airs-bp23 depends on current repo
f=$(grep ${pname} go.mod)
if [ -z "$f" ]; then
  echo "No need to test airs-pb3"
else
  echo "airs-pb3 will be tested now..."
  # run tests
  go test -race ./...
  if [[ "$gh_event" == "push" ]];then 
    echo "Push new version of $reponame to git"
  fi
fi

# Need to commit bp3 with new repo
if [[ "$gh_event" == "push" ]];then 
  git config --global user.email "ivvist@gmail.com"
  git config --global user.name "ivvist"
  git add .
  git commit -m "$reponame is updated"
  git push
fi

