#!/bin/bash

echo "Clone https://github.com/$org/$repo"
git clone https://github.com/$org/$repo repo
cd repo

echo "Source branch '$source_branch' does not exist."
# Set branch names based on parameter
new_branch="rc"
source_branch="main"
# Ensure the source branch exists before attempting to copy
if ! git show-ref --verify --quiet refs/heads/$source_branch; then
    echo "Source branch '$source_branch' does not exist."
    exit 1
fi

echo "Deleting exiting rc"
# Delete the old branch if it exists
if git branch -r | grep -qE "origin/$new_branch$"; then
    git push origin --delete $new_branch
    echo "Deleted branch '$new_branch'."
fi

# Create new branch from the source branch
git config --local user.email "v.istratenko@dev.untill.com"
git config --local user.name "upload-robot"

git fetch origin
git checkout $source_branch
git pull origin $source_branch
git checkout -b $new_branch
git switch $new_branch
git commit -am "Release candidate create"
git push origin rc
cd ..

echo "Branch 'github.com/$org/$repo $new_branch' has been created from 'github.com/$org/$repo $source_branch' and pushed to origin."
