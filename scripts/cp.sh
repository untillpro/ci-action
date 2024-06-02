#!/bin/bash

# The input is a comma-separated list of commit hashes
echo "Starting cherry-pick..."
if [ -z "$branch" ];  then
  echo "Branch is not defined"
  exit 1
fi
echo "https://github.com/$org/$repo"

if [ -z "$branch" ];  then
commit_hashes_arr="$commit_list"
for word in $commit_hashes_arr; do
  # Append word to the list
  commit_hashes="$commit_hashes $word"
done
echo "commit_hashes: $commit_hashes"

trimmedsha=$(echo "$commit_hashes" | sed 's/^[ \t]*//;s/[ \t]*$//')
lengthsha=${#trimmedsha}
if [ $lengthsha -eq 0 ]; then
  if [[ "$repo" == "airs-bp3" ]]; then
    echo "No commits are required to cherry-pick. Will upgrade voedger version."
  else
    echo "List of commits to cherry-pick is empty"
    exit 1
  fi
else 
  if [[ "$branch" == "rc" ]]; then
    orig_branch="main"   
  else
    orig_branch="rc"   
  fi
  echo "original branch: $orig_branch"

  git fetch --all
  for commit_hash in $commit_hashes; do
    # Check if commit exists in current branch
    cmt=$(git branch -r --contains $commit_hash | sed 's/origin\///')
    cmt=$(echo "$cmt" | sed 's/^[ \t]*//;s/[ \t]*$//')
    echo "cmt2=$cmt"
    if [ -z "$cmt" ]; then
      echo "Commit $commit_hash does not exists"
      exit 1	
    fi 
    if [[ $cmt != $orig_branch ]]; then
      echo "Commit $commit_hash does not belong to original branch $orig_branch"
      exit 1	
    fi 
  done
fi

git clone -b $branch "https://github.com/$org/$repo" chp || {
   echo "Something went wrong with clone branch"
   exit 1
}
cd chp

rc=$(git branch --show-current)
if [ -z "$rc" ];  then
    echo "Please go to git branch and run script from there"
    exit 1
fi
if [ "$rc" = "main" ];  then
    echo "Please go to git branch and run script from there. It does not in main."
    exit 1
fi
echo "Current branch: $rc"


# Check if commit hashes were provided
if [ $lengthsha -eq 0 ]; then # Means pb3 wans to update voedger version
  git config --local user.email "v.istratenko@dev.untill.com"
  git config --local user.name "upload-robot"
  git config --global url.https://$github_token@github.com/.insteadOf https://github.com/
  if [[ "$branch" == "rc" ]]; then
    go get github.com/voedger/voedger@rc
  else
    go get github.com/voedger/voedger@release
  go mod tidy
  git commit -am "Cherry-pick auto-create" --allow-empty 
  git push origin $rc
  exit 0
fi

# Initialize a space-separated string to hold sorted commit hashes
sorted_commits=""
# Loop through the hashes, get their commit dates, and sort them
# Capture the sorted hashes into a string variable
sorted_commits=$(for commit in $commit_hashes; do
    # Get the commit date using %ci, output with commit hash
    commit_info=$(git show -s --format=%ci $commit)
    echo "$commit_info $commit"
done | sort | awk '{print $4}')

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
echo "The script directory is: $SCRIPT_DIR"
# Process each sorted commit hash separately
git config --local user.email "v.istratenko@dev.untill.com"
git config --local user.name "upload-robot"
for commit_hash in $sorted_commits; do
    echo "Cherry-picking commit $commit_hash from main to $branch..."
    echo $(git show -s --format=%ci $commit_hash) $commit_hash	
    commit_hash=$(echo $commit_hash | tr -d ' ')
    echo "commiting sha: $commit_hash"
    git cherry-pick "$commit_hash" || {
        echo "Error cherry-picking commit $commit_hash. Aborting."
        exit 1
    }
done
git config --global url.https://$github_token@github.com/.insteadOf https://github.com/
if [[ "$branch" == "rc" ]]; then
  go get github.com/voedger/voedger@rc
else
  go get github.com/voedger/voedger@release
go mod tidy
git commit -am "Cherry-pick auto-create" --allow-empty 
git push origin $rc

echo "Cherry-pick completed successfully."
