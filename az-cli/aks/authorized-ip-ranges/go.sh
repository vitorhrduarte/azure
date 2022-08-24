##!/usr/bin/env bash


#################
#
# Functions
#
#################



showHelp() {
cat << EOF  
Purpose:
  Add current VM PIP to the Authorized IP Ranges for desired AKS Clustee

Usage: 

bash go.sh --help/-h  [for help]
bash go.sh -n/--name <aks name> -r/--rgroup <aks resource group>

Install Pre-requisites jq

-h, -help,          --help                  Display help

-n, -name,          --name                  Name of thr AKS Cluster

-r, -rgroup,        --rgroup                Name of the AKS Resurce Group 

EOF
}

options=$(getopt -l "help::,name:,rgroup:" -o "h::n:r:" -a -- "$@")

eval set -- "$options"

while true
do
case $1 in
-h|--help) 
    showHelp
    exit 0
    ;;
-r|--rgroup)
    shift
    AKS_RG_NAME=$1
    ;;
-n|--name)
    shift
    AKS_NAME=$1
    ;;
--)
    shift
    break
    exit 0
    ;;
esac
shift
done



funcCheckArguments () {

  if [[ -z $AKS_NAME ]]
  then
    echo "Empty AKS Name"
    exit 1
  fi

  if [[ -z $AKS_RG_NAME ]]
  then
    echo "Empty AKS RG Name"
    exit 1
  fi
}




##################
#
#    MAIN
#
#################


## Check Arguments
funcCheckArguments

## Get the PIP for the current VM
echo "Getting PIP for current VM"
PIP=$(curl -s -4 ifconfig.io) 

## Parsing the PIP
CURRENTPIP=$(az aks show --resource-group $AKS_RG_NAME --name $AKS_NAME --query apiServerAccessProfile.authorizedIpRanges | jq -r ". | @csv" | sed s/\"//g)
FINALLIST="$PIP/32,$CURRENTPIP"

## Declare the Array for sorting and uniq
declare -A words

IFS=","
for w in $FINALLIST; do
  words+=( [$w]="" )
done

FLIST=$(echo ${!words[@]} | sed 's/ /,/g')

## Set Empty Auth Ranges
echo "Set Empty List"
az aks update \
  --resource-group $AKS_RG_NAME \
  --name $AKS_NAME \
  --api-server-authorized-ip-ranges ""

## Update the Auth Ranges with current IP as well as all previous IP in the Ranges
echo "Update Allowed List"
echo "az aks update --resource-group $AKS_RG_NAME --name $AKS_NAME --api-server-authorized-ip-ranges $FLIST --debug" | bash 
