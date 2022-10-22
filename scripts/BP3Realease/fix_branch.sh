#!/bin/bash

if [ "$#" -ne 5 ]; then
    echo "Please add 5 arguments: org, repo, branch from, branch to, action type(new/fix)"
    read -p "Press [Enter] to exit."
    exit 1	
fi

org=$1
repodir=$2
oldbranch=$3
newbranch=$4

org="${org%%[[:cntrl:]]}"
repodir="${repodir%%[[:cntrl:]]}"
oldbranch="${oldbranch%%[[:cntrl:]]}"
newbranch="${newbranch%%[[:cntrl:]]}"

if [[ -d "${repodir}-${newbranch}" ]]
then
    echo ""${repodir}-${newbranch}" already exists. Please delete it first."
    read -p "Press [Enter] to complete"
    exit 1	
fi

# Take my own forked repo
git clone -b ${oldbranch} https://github.com/${org}/${repodir} "${repodir}-${newbranch}"

cd ${repodir}-${newbranch}

cp ../fix_gomod.sh fix_gomod.sh

# delete existing branch - not needed old one
git push origin :$newbranch 

# set upstream to parent heeus repo 
git remote add upstream https://github.com/${org}/${repodir}

# get last code from upstream
git pull -p upstream ${oldbranch}

# create devbranch with topic number
git checkout -b ${newbranch}

# get last from newbranch
git pull -p -r origin ${newbranch}

# Replace all dependencies with the last from repo/rc in go.mod 
sh fix_gomod.sh $5 

rm fix_gomod.sh

go mod tidy

git add .
git commit -m "update go.mod"
git push -u origin ${newbranch}

cd ..

