##!/usr/bin/env bash
set -e


showHelp() {
cat << EOF  
Usage: 

bash get-creationTime.sh --help/-h  [for help]
bash get-creationTime.sh -s/--subid <subscription id> -r/--rgname <resrouce group name>

Install Pre-requisites jq and dialog

-h, -help,          --help                  Display help

-s, -subid,       --subid                   Azure Subscription ID

-r, -rgname,      --rgname                  Resource Name 

EOF
}

options=$(getopt -l "help::,subid:,rgname:" -o "h::s:r:" -a -- "$@")

eval set -- "$options"

while true
do
case $1 in
-h|--help) 
    showHelp
    exit 0
    ;;  
-s|--subid)
    shift
    SUB_ID=$1
    ;;  
-r|--rgname)
    shift
    RG_NAME=$1
    ;;  
--)
    shift
    break
    exit 0    
    ;;  
esac
shift
done

ARM_URL="https://management.azure.com/subscriptions/$SUB_ID/resourcegroups/$RG_NAME/?api-version=2021-04-01&%24expand=createdTime"
TOKEN=$(az account get-access-token --query 'accessToken' -o tsv)

OUTPUT=$(curl -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" "$ARM_URL")

echo ""
echo $OUTPUT | jq -r '(["ResourceName","CreationTimeStamp"] | (., map(length*"-"))),[.name, .createdTime] | @tsv' | column -t
