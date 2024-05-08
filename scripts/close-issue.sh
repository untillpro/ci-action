#!/bin/bash

# The input is a comma-separated list of commit hashes
if [ -z "$repo" ];  then
  echo "Repo is not defined"
  exit 1
fi
if [ -z "$org" ];  then
  echo "Org is not defined"
  exit 1
fi
if [ -z "$issue" ];  then
  echo "Issue number is not defined"
  exit 1
fi

echo "https://github.com/$org/$repo"
gh issue close $issue -R "https://github.com/$org/$repo"