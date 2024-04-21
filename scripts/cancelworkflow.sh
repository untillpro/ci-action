#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Cancel workflow script was not running. Arguments: $#"
    exit 0
fi

rp=${repo}
br=${branch{
wf=${running-workflow}
echo "repo: ${rp}"
echo "branch: ${br}"
echo "workflow: ${wf}"

# Declare an array to hold the workflow details
declare -a workflows=()

# Counter to keep track of the number of lines read
i=0

# Temporary array to hold the set of three lines (workflowName, databaseId, headBranch)
temp=()

# Execute your gh command and read the output line by line
while IFS= read -r line; do
    # Add the line to the temporary array
    temp[i]="$line"

    # Increment the counter
    ((i++))

    # Every three lines, join them into a single array element and reset
    if [[ $i -eq 1 ]]; then
        # Concatenate the elements of temp array into a string, separated by a delimiter (e.g., "|")
        workflows+=("${temp[0]}")

        # Reset the counter and temporary array
        i=0
        temp=()
    fi
done < <(gh run list -b "${br}" --workflow "${wf}" --limit 3 -e pull_request_target  -s in_progress --json 'databaseId' --jq '.[] | .databaseId' -R "${rp}")

# Output the results
for workflow in "${workflows[@]}"; do
    echo "Running workflow: $workflow. Trying to cancel..."
    gh run cancel $workflow || true 	    	     
done
