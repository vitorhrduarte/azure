#!/bin/zsh

function help {
  cat <<-EOF
Usage: ./scriptname -i UserOrGroupID [-t Type]

This script retrieves all role assignments of a given Azure User or Group and details of those roles. 

Options: 
  -i Define Azure User or Group ID. This option is required.
  -t Specify the type of principal. Use 'u' for User and 'g' for Group. Default value is 'u' (User).
  -h Show this help message and exit.

EOF
}

principal_type="u"

while getopts ":i:t:h" option
do
    case "$option" in
    i)
      ansusrid=$OPTARG
      ;;
    t)
      principal_type=$OPTARG
      ;;
    h)
      help
      exit
      ;;
    *)
      echo "Incorrect option provided"
      exit 1
      ;;
    esac
done

if [ -z "$ansusrid" ]; then
    echo "Azure User/Group ID is required. Use -i option."
    exit 1
fi

# check if the user or group exists
if [ "$principal_type" = "u" ]; then
    if ! az ad user show --id $ansusrid >/dev/null 2>&1; then
        echo "Azure User ID does not exist in Azure Active Directory"
        exit 1
    fi
elif [ "$principal_type" = "g" ]; then
    if ! az ad group show --group $ansusrid >/dev/null 2>&1; then
        echo "Azure Group ID does not exist in Azure Active Directory"
        exit 1
    fi
else
    echo "Incorrect principal type. Use 'u' for user and 'g' for group."
    exit 1
fi

rolelist=(${(f)"$(az role assignment list --all --include-groups --include-inherited --assignee $ansusrid -o json | \
            jq -r '.[].roleDefinitionName' | \
            sort | \
            uniq)"}) 

declare -i j=1

for i in $rolelist; do 
    az role definition list -n $i -o json | jq ".[]" > output$j.json
    python3 process_json.py output$j.json
    j+=1
done

exit 0

