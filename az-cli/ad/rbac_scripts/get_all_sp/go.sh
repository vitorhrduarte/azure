#!/bin/zsh

s_help() {
  echo "\nScript Usage:"
  echo "--------------------------------------------------------"
  echo "./go.sh"
  echo "\nThis script retrieves all Azure AD service principals, converts the list to JSON format, and subsequently converts the received JSON into CSV format." 
  echo "Finally, it stores this output as a CSV file with the current date included in the filename."
  echo "The output CSV will contain the following headers: IS-ENABLED, APP-DISPLAY-NAME, APP-ID, CREATED-IN, DISPLAY-NAME, SP-ID, SP-TYPE."
  echo "\nThe output will be stored in all-aad-sp-{current date}.csv"
  echo "--------------------------------------------------------\n"
  exit 0
}

if [[ ( $1 == "--help") ||  $1 == "-h" ]]
then
  s_help
fi


az ad sp list --all -o json | \
    jq -r '(["IS-ENABLED","APP-DISPLAY-NAME","APP-ID","CREATED-IN","DISPLAY-NAME","SP-ID","SP-TYPE"]),(.[] | [(.accountEnabled|tostring),(.appDisplayName|tostring),(.appId|tostring),.createdDateTime,(.displayName|tostring),(.id|tostring),(.servicePrincipalType|tostring)]) | @csv' > all-aad-sp-`date +%Y-%m-%d`.csv

