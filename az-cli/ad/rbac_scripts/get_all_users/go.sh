#!/bin/zsh

s_help() {
  echo "\nScript Usage:"
  echo "--------------------------------------------------------"
  echo "./go.sh"
  echo "\nThis script retrieves all Azure AD users, converts the list to JSON format, and formats the JSON for output." 
  echo "If the office location is not specified, 'Null' will be output instead. This output is then joined with semicolons and outputted in columns, separated by semicolons."
  echo "The output will include the following details: User ID, Given Name, Display Name, and Office Location(or 'Null' if not specified)."
  echo "\nThe output will be stored in all-aad-users-{current date}.txt"
  echo "--------------------------------------------------------\n"
  exit 0
}

if [[ ( $1 == "--help") ||  $1 == "-h" ]]
then
  s_help
fi


az ad user list -o json | \
    jq -r '.[] | [ .id, .givenName, .displayName, (if .officeLocation == "" then "Null" else .officeLocation end) ] | join(";")' | \
    column -t -s ";" > all-aad-users-`date +%Y-%m-%d`.txt

