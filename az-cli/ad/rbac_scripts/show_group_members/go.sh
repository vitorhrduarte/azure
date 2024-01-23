#!/usr/bin/env zsh

usage() {
    echo "Usage: $0 -s <Security Group Name> [-y]"
    echo -e "\n-s   The Security Group Name you want to search."
    echo ""
    echo "If you already know the gropup ID then use this ways: ./go.sh -s <group id> -y"
    echo -e "\n-y   Skip group listing part and start with member listing."
    exit 1
}

skip_group_list='false'

while getopts "s:yh" opt; do
  case ${opt} in
    s )
      searchstr=$OPTARG
      ;;
    y )
      skip_group_list='true'
      ;;
    h )
      usage
      exit 0
      ;;
    \? )
        echo "Invalid option: $OPTARG" 1>&2
        usage
        ;;
    : )
        echo "Invalid option: $OPTARG requires an argument" 1>&2
        usage
        ;;
  esac
done
shift $((OPTIND -1))

if [ -z "${searchstr}" ]; then
    usage
fi
output_file="group_members.csv"
if [[ "$skip_group_list" == 'false' ]]; then
    
    # Since users does not know the ID for the desired group we need to search for it fisrt 
    grpid=$(az ad group list -o json | \
        jq --arg sstr "$searchstr" -r '(["SEC-GRP-NAME","SEC-GRP-ID","SEC-GRP-CREATED-TIME"] | (., map(length*"-"))),(( sort_by(.displayName)) | .[] | select(.displayName | contains ($sstr))  | [.displayName, .id, .createdDateTime]) | @csv' | \
        column -t -s "," | \
        fzf -e | \
        awk '{print $2}' | \
        tr -d '"') > $output_file
     
    # The value of the Var grpid comes from the previous selection

    az ad group member list -g $grpid -o json | \
        jq -r '(["USER-NAME","USER-JOB","USER-MAIL","USER-LOCATION","USER-UPN","USER-ID"] | (., map(length*"-"))),(sort_by(.givenName)| .[] | [.givenName, .jobTitle, .mail, .officeLocation, .userPrincipalName, .id ])  | join(";") ' | \
        column -t -s ";" > $output_file

elif [[ "$skip_group_list" == 'true' ]]; then

    # If user already know, then it will speed up the process
    az ad group member list -g $searchstr -o json | \
        jq -r '(["USER-NAME","USER-JOB","USER-MAIL","USER-LOCATION","USER-UPN","USER-ID"] | (., map(length*"-"))),(sort_by(.givenName)| .[] | [.givenName, .jobTitle, .mail, .officeLocation, .userPrincipalName, .id ])  | join(";") ' | \
        column -t -s ";" >> $output_file
fi



