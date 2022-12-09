#!/bin/bash                    
                                           
jqbase64 () {
  echo "$file" | base64 -d | jq -r "$1"
}

doCheckPR ()  {

  overalsize=100000
  singlelimit=100000
  cntlimit=200  

  # Set git token
  header="Accept: application/vnd.github+json"
  repo_full_name=$(git config --get remote.origin.url | sed 's/.*:\/\/github.com\///;s/.git$//')
  files="https://api.github.com/repos/$repo_full_name/pulls/$pr_number/files"

  body=$(curl -s -u "${token}:x-oauth-basic" -H "$header" "$files")

  ln=0
  maxln=0
  maxfile=""
  fcnt=0
  for file in $(echo "$body" | jq -r '.[] | @base64'); do
    fn=$(jqbase64 '.filename') 
    fc=$(jqbase64 '.patch') 
    fc=${fc#*@@}
    fc=${fc#*@@}
    newln=${#fc}
    if [ $newln -gt $maxln ];then
	maxln=$newln
        maxfile=$fn
    fi
    ((ln +=$newln))
    ((fcnt=fcnt+1))
  done

  echo "Number of files in Pull request: $fcnt"

  if [ $ln -gt $overalsize ];then
	echo "::error::Total size $ln of changed files exceeds limit $overalsize bytes"
	exit 1
  fi
  if [ $maxln -gt $singlelimit ];then
	echo "::error::Largest file '$maxfile' has size $maxln. It exceeds limit $singlelimit bytes"
	exit 1
  fi
  if [ $fcnt -gt $cntlimit ];then
	echo "::error::Number of files $fcnt in Pull request exceeds limit $cntlimit files"
	exit 1
  fi
}

doCheckPR     
