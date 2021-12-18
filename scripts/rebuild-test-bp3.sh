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

# get airs-bp3 to bp3 folder                                   
git clone https://github.com/untillpro/airs-bp3
# go to airs-bp3 repo folder
cd airs-bp3

# check if airs-bp23 depends on current repo
f=$(grep ${pname} go.mod)
if [ -z "$f" ]; then
  echo "No need to test airs-pb3"
else
  echo "airs-pb3 will be tested now..."
  # run tests
  go test -race ./...
fi

