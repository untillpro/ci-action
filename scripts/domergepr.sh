#!/bin/bash                    

jqbase64 () {
  echo "$team" | base64 -d | jq -r "$1"
}

  # Check if author is Developer
  # Get author of the pull request
  auth_login=$(gh pr view $pr_number --json author -R ${repo}| jq -r '.[].login')
  echo "Pull request author: $auth_login"

  # Get pull request body
  needbody=0
  body=$(gh pr view $pr_number --json body -R ${repo}| jq -r '.body')
  repl="Resolves #"
  if [[ "$body" == *"$repl"* ]]; then
    prnum="(#$pr_number)"
    body=$body$prnum
    newrepl="#"
    body=${body/$repl/$newrepl}
    needbody=1
  fi 

  userfound=0
  header="Accept: application/vnd.github+json"
  urlteams="https://api.github.com/repos/${repo}/teams"

  # Get teams, included in project 
  teams=$(curl -s -u "${token}:x-oauth-basic" -H "$header" "$urlteams")
  for team in $(echo "$teams" | jq -r '.[] | @base64'); do
    slug=$(jqbase64 '.slug') 
    echo "Team: $slug"
    if [[ slug=="devs" ]] || [[ slug=="developers" ]]; then
      url=$(jqbase64 '.url') 
      users=$(curl -s -u "${token}:x-oauth-basic" -H "$header" "$url/members")
      for user in $(echo "$users" | jq -r '.[].login'); do
        echo "user: $user"
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

  # Check line count
  loc_stats=$(gh pr view $pr_number --json additions,deletions -R ${repo})
  additions=$(echo "$loc_stats" | jq -r '.additions')
  deletions=$(echo "$loc_stats" | jq -r '.deletions')
  total=$((additions + deletions))

  echo "Pull request has $additions additions and $deletions deletions. Total: $total lines."

  if [[ $total -gt 200 ]]; then
    echo "Pull request $pr_number is not auto-merged because it changes more than 200 lines."
    exit 0
  fi

  # Merge pull request with squash
  if [[ $needbody -eq 0 ]]; then 
    gh pr merge https://github.com/${repo}/pull/$pr_number --squash --delete-branch 
  else 
    gh pr merge https://github.com/${repo}/pull/$pr_number -b " " -t "$body" --squash --delete-branch 
  fi
  
  # Delete remote branch
  # git push origin :$br_name
