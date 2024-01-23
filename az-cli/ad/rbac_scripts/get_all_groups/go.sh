#!/bin/zsh

# Help function to display script usage
s_help() {
  echo "\nScript Usage:"
  echo "--------------------------------------------------------"
  echo "./go.sh"
  echo "\nThis script retrieves all Azure AD security groups, converts the list to JSON format, and formats the JSON for output."
  echo "If the description is not specified, 'Null' will be output instead. This output is then joined with semicolons and outputted in columns, separated by semicolons."
  echo "The output will include the following details: Group ID, Group Name, and Description (or 'Null' if not specified)."
  echo "\nThe output will be stored in all-aad-security-groups-{current date}.txt"
  echo "--------------------------------------------------------\n"
  exit 0
}

# Check if the --help or -h flag is provided to display script usage
if [[ ( $1 == "--help") ||  $1 == "-h" ]]
then
  s_help
fi

# Step 1: Retrieve a list of Azure AD security groups in JSON format
az ad group list --filter "securityEnabled eq true" --output json | \

# Step 2: Process the JSON data and create a CSV-like file
jq -r '.[] | [.createdDateTime,.id,((.displayName // "Null") | tostring),(.mail // "Null")] | @csv' | \

# Step 3: Format the data into columns separated by semicolons
column -t -s ";" > "all-aad-security-groups-$(date +%Y-%m-%d).txt"