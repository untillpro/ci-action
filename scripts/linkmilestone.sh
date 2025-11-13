#!/usr/bin/env bash
set -Eeuo pipefail

# Get milestone list
rawmilestones=$(gh api repos/${repo}/milestones --jq '.[] | .title')
# Make arrays from milestones string
readarray -t milestones <<< "$rawmilestones"
l=${#milestones[@]}
# Link to milestone is possible if only 1 Milestone exists
if [ $l -eq 1 ]; then
  rawml=${milestones[0]}
  ml="${rawml// /}"
  if [ -z "$ml" ]; then
    gh issue reopen ${issue} --repo ${repo}
    echo "::error::No open milestones found"
    exit 1
  fi
  gh issue edit ${issue} --milestone ${ml} --repo ${repo}
else
  gh issue reopen ${issue} --repo ${repo}
  if [ $l -eq 0 ]; then
     echo "::error::No open milestones found"
  fi
  if [ $l -gt 1 ]; then
     echo "::error::More than one open milestone found."
  fi
  exit 1
fi

