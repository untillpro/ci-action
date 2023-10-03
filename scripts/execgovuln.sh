#!/bin/bash

# Execute govulncheck
govulncheck ./... >> golulnres

# Main text file
main_file="golulnres"
# Exception file
exception_file=".govulnc-exclude"

# Create a temporary file to store the filtered content
temp_file="filtered.txt"

# Read the exception codes into an array
mapfile -t exception_codes < "$exception_file"

# Initialize a flag to determine whether to keep or skip a section
skip_section=0

# Loop through the main text file
while IFS= read -r line; do
  # Check if the line starts with "Vulnerability #"
  if [[ $line == "Vulnerability #"* ]]; then
    # Extract the code from the line
    code="${line##*: }"
    # Check if the code is in the exception list
    if [[ " ${exception_codes[*]} " =~ " $code " ]]; then
      skip_section=1  # Set the flag to skip this section
    else
      skip_section=0  # Set the flag to keep this section
    fi
  fi

  # If the section is not in the exception list, write it to the temp file
  if [ $skip_section -eq 0 ]; then
    echo "$line" >> "$temp_file"
  fi
done < "$main_file"

issue_exist=0
while IFS= read -r line; do
  if [[ $line == "Vulnerability #"* ]]; then
    issue_exist=1  
    break
  fi 
done < "$temp_file"

if [ $issue_exist -eq 1 ]; then
  echo "::error::One or more vulnerabilities found in packages. See detailed report."	   
  cat "$temp_file" 
  exit 1
fi

