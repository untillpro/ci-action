#!/bin/bash

# The input is a comma-separated list of commit hashes
echo "Starting checrry-pick..."
if [ -z "$rc" ];  then
  echo "Branch is not defined"
  exit 1
fi
git checkout -b $branch
commit_hashes_arr="$commit_list"
echo "sha commiits: commit_hashes_arr"
normalized=$(echo "$commit_hashes_arr" | tr '.,\n' ' ')
readarray -d " " -t commit_hashes <<< "$normalized"

echo $(git branch --show-current)
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
if [ -z "$commit_hashes" ]; then
    echo "Usage: $0 <comma-separated list of commit hashes>"
    exit 1
fi

# Initialize an array to hold the sorted commit hashes
declare -a sorted_commits

# Loop through the hashes, get their commit dates, and sort them
# Then read line by line into the array
while IFS= read -r line; do
    sorted_commits+=("$line")
done < <(for commit in $commit_hashes; do
    # Using %ci to get the commit date, you can also use %ct for UNIX timestamp
    echo $(git show -s --format=%ci $commit) $commit
done | sort | awk '{print $4}')

# Now, you can use sorted_commits array as needed
echo "Sorted commits:"
printf "%s\n" "${sorted_commits[@]}"
# Loop through the array and cherry-pick each commit from the "main" branch
for commit_hash in "${sorted_commits[@]}"; do
    echo "Cherry-picking commit $commit_hash from main to rc..."
    echo $(git show -s --format=%ci $commit_hash) $commit_hash	
    commit_hash=$(echo $commit_hash | tr -d ' ')
    git cherry-pick "$commit_hash" || {
        echo "Error cherry-picking commit $commit_hash. Aborting."
        exit 1
    }
    git push origin $rc
done

echo "Cherry-pick completed successfully."
