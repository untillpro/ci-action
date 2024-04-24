#!/bin/bash

# Variables
REPO=$repo 
TITLE=$name
BODY=$body
ASSIGNEE=$assignee 
LABEL=$label 

echo "REPO :    $repo"
echo "TITLE:    $name"
echo "BODY :    $body"
echo "ASSIGNEE: $assignee"
echo "LABEL:    $label"

if [ -z "$REPO" ] || [ -z "$TITLE" ] || [ -z "$BODY" ] || [ -z "$ASSIGNEE" ]; then
    echo "Error: Issue not created because some patrameters are empty."
    exit 0
fi
# Create the issue and assign it
gh issue create --repo "$REPO" --title "$TITLE" --body "$BODY" --assignee "$ASSIGNEE" --label "$LABEL"

