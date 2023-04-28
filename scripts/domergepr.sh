#!/bin/bash                    

jqbase64 () {
  echo "$team" | base64 -d | jq -r "$1"
}

# Get list of open Pull requests
prlist=$(gh pr list --state open --json number -R ${repo} | jq -r '.[].number')
for pr_number in ${prlist}
do
  # Check if author is Developer
  # Get author of the pull request
  auth_login=$(gh pr view $pr_number --json author -R ${repo}| jq -r '.[].login')
  echo "Pull request author: $auth_login"

  userfound=0
  header="Accept: application/vnd.github+json"
  urlteams="https://api.github.com/repos/${repo}/teams"

  # Get teams, included in project 
  teams=$(curl -s -u "${token}:x-oauth-basic" -H "$header" "$urlteams")
  for team in $(echo "$teams" | jq -r '.[] | @base64'); do
    slug=$(jqbase64 '.slug') 
    if [[ slug=="devs" ]] || [[ slug=="developers" ]]; then
      url=$(jqbase64 '.url') 
      users=$(curl -s -u "${token}:x-oauth-basic" -H "$header" "$url/members")
      for user in $(echo "$users" | jq -r '.[].login'); do
        # Check if author belongs to a team
        if [[ $auth_login == $user ]]; then   
	 userfound=1	
        fi
      done
    fi
  done

  if [[ $userfound -eq 0 ]]; then 
    # User is not from pour team
    echo "Pull request $pr_number is not auto-merged, because it's author $auth_login not from developers team."
    exit 0
  fi

  # Merge pull request with squash
  gh pr merge https://github.com/${repo}/pull/$pr_number --squash --admin
done

