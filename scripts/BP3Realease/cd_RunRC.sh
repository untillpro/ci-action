#!/bin/bash

# Clone from branch "main" last code and push to branch "rc"

if [ "$#" -ne 2 ]; then
    echo "Please add 2 arguments: repo name, action type(new/fix)"
    read -p "Press [Enter] to exit."
    exit 1	
fi

org="untillpro"
repodir=$1
if [[ $2 == "new" ]]; then 
  oldbranch="main"
  newbranch="rc"
else
  oldbranch="rc"
  newbranch="rcfix"
fi

sh fix_branch.sh $org $repodir $oldbranch $newbranch $2

read -p "Press [Enter] to complete RC"
