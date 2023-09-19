#!/bin/bash                    

  isNext( ) {
    # Convert the input date string to a Unix timestamp
    date_string="${1//./-}"
    input_date=$(date -d "$date_string" +"%s")
    # Get the current date in Unix timestamp format
    current_date=$(date +"%s")    
    res=0 
    if [ $input_date -gt $current_date ]; then
      res=1
    fi
    echo $res
  }                

  # Get milestone list
  milestones=$(gh api repos/${repo}/milestones --jq '.[] | .title')
  for milestone in $milestones; do
    ml=$milestone    
    hasfound=$(isNext "$ml")
    if [ "$hasfound" -eq 1 ]; then
	gh issue edit ${issue} --milestone ${milestone} --repo ${repo}
 	exit 0
    fi	
  done
