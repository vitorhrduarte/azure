#!/usr/bin/env zsh

function usage {
    echo "Usage: $0 -s <principal search string>"
    echo ""
    echo "This script is used to fetch user or group information from Azure Active Directory."
    echo "You can pass user principal search string (like name) as a command line argument with -s option."
    echo "If you know the principal ID, use -y flag with -s option."
    echo ""
    echo "Options:"
    echo "  -s    Specify the user principal search string"
    echo "  -y    Use this flag if you already know the user principal id"
    echo "  -h    Prints this help information"
    exit 1
}

know_principal_id=false
output_file="get_user_group_details.csv"  # Specify the output file name here

while getopts ":s:yh" opt; do
  case ${opt} in
    s )
      usrn=$OPTARG
      ;;
    y )
      know_principal_id=true
      ;;
    h )
      usage
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

if [[ -z "$usrn" ]]; then
  usage
fi



if [[ "$know_principal_id" == "false" ]]; then
    
    # Since user does not principal ID we need to search by a search string    
    user_list=$(az ad user list -o json | \
        jq --arg usr $usrn -r '(["USER-ID","USER-MAIL","USER-UPN"] | (., map(length*"-"))),(.[] | select(.userPrincipalName | ascii_downcase | contains($usr)) | [ .id, .mail, .userPrincipalName ]) | join(";")')

    echo $user_list | awk 'NR<3{print $0;next}{print $0| "sort --ignore-case -V -t \";\" -k 2"}' | column -t -s ";" > $output_file

    # Process Principal ID now...
    echo ""
    read "?Input User ID: " usrid
  
    group_list=$(az ad user get-member-groups  --id $usrid -o json)
    filtered_groups=$(echo $group_list | jq -r '(["SEC-GROUP-DISPLAY-NAME","GROUP-ID"] | (., map(length*"-"))),(.[] | [.displayName, .id]) | join(";")' | awk 'NR<3{print $0;next}{print $0| "sort --ignore-case -V -t \";\" -V -k 1"}')
  
    echo $filtered_groups | awk 'NR<3{print $0;next}{print $0| "sort --ignore-case -V -t \";\" -k 1"}' | column -t -s ";" >> $output_file

elif [[ "$know_principal_id" == "true" ]]; then
    
    # Since user already know the principal this will speed up things
    group_list=$(az ad user get-member-groups  --id $usrn -o json)
    
    filtered_groups=$(echo $group_list | jq -r '(["SEC-GROUP-DISPLAY-NAME","GROUP-ID"] | (., map(length*"-"))),(.[] | [.displayName, .id]) | join(";")' | awk 'NR<3{print $0;next}{print $0| "sort --ignore-case -V -t \";\" -V -k 1"}')
    
    echo $filtered_groups | awk 'NR<3{print $0;next}{print $0| "sort --ignore-case -V -t \";\" -k 1"}' | column -t -s ";" >> $output_file
fi