#!/usr/bin/env zsh

display_usage() {
    echo "This script requires a user/group ID passed with '-i'"
    echo -e "\nUsage: $0 -i <user_group_id>\n"
    echo "Note, the output will be in STD but also in a file named output.csv in current execution directory"
}

# If less than two arguments supplied, display usage 
if [  $# -le 1 ] 
then
    display_usage
    exit 1
fi 

# Check whether user had supplied -h or --help, If yes display usage 
if [[ ( $# == "--help") ||  $# == "-h" ]]
then
    display_usage
    exit 0
fi

while getopts ":i:h" opt; do
  case ${opt} in
    i )
      ansusrid=$OPTARG
      ;;
    h )
      display_usage
      exit 0
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      display_usage
      exit 1
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      display_usage
      exit 1
      ;;
  esac
done

shift $((OPTIND -1))

# Validate user/group ID
user_exists=$(az ad user show --id $ansusrid --query id --output tsv 2>/dev/null)
group_exists=$(az ad group show --group $ansusrid --query id --output tsv 2>/dev/null)

if [[ -z "$user_exists" ]] && [[ -z "$group_exists" ]] ; then
    echo "User/Group ID not found in Azure AD. Please provide a valid user/group ID."
    exit 1
else
    results=$(az role assignment list --all --include-groups --include-inherited --assignee $ansusrid -o json | jq  -r '.[] | [.roleDefinitionId,.roleDefinitionName,.principalName,.principalType] | @csv')
    echo $results > output.csv
    echo $results
fi




