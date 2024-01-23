#!/bin/zsh

function usage() {
    echo "Usage:"
    echo "-f filepath : Path to the file containing the list of group names, one per line"
    echo "-g group_id : ID of a single group to be checked"
    echo "Only one of -f or -g can be provided at a time"
    echo "Use -h for displaying this help information"
    exit 1
}

function displayGroupOwners() {
    group=$1
    output_file="group_owners.csv"
    # Checks if group exists
    if az ad group show -g $group > /dev/null 2>&1; then
        echo "ID,DISPLAY-NAME,MAIL,OFFICE-LOCATION" > "$output_file"
        az ad group owner list -g $group -o json | \
        jq -r '.[] | [.id, .displayName, .mail, .officeLocation] | @csv' | \
        sort --ignore-case -t "," -V -k 2 >> "$output_file"

        echo ""
        echo "Owners of AAD SEC GRP $group are listed in $output_file"
    else
        echo "Group $group does not exist in Azure Active Directory, skipping ..."
    fi
}


while getopts "f:g:h" opt; do
  case ${opt} in
    f )
      filepath=$OPTARG
      ;;
    g )
      group_id=$OPTARG
      ;;
    h )
      usage
      ;;
    \? )
      usage
      ;;
  esac
done

if [ -n "${filepath}" ] && [ -n "${group_id}" ]; then
    # both options were provided
    echo "-f and -g cannot be provided at the same time!"
    usage
elif [ -z "${filepath}" ] && [ -z "${group_id}" ]; then
    # neither option was provided
    usage
fi

# if -f option was provided
if [ -n "${filepath}" ]; then
    if [ ! -f "${filepath}" ]; then
        echo "File ${filepath} does not exist"
        exit 1
    fi

    listgrp=( $(<$filepath) )

    for i in "${listgrp[@]}"; do
        displayGroupOwners $i
    done | column -t -s ";"
else
    # if -g option was provided
    displayGroupOwners $group_id | column -t -s ";"
fi

