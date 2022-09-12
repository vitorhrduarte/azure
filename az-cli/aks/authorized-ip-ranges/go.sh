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

-n, -name,          --name                  Name of the AKS Cluster

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
    echo "Exiting..."
    exit 1
  fi

  if [[ -z $AKS_RG_NAME ]]
  then
    echo "Empty AKS RG Name"
    echo "Exiting..."
    exit 1
  fi
}


funcCheckRG () {
   ## Check if RG Exists
   echo "Checking if RG for $AKS_NAME exists..."
   EXISTS_RG=$(az group list \
     --output json | jq -r ".[] | select ( .name == \"$AKS_RG_NAME\") | [ .id ] | @tsv" | wc -l)
}


funcCheckAKS () {
  ## Check if AKS exists
  echo "Check if $AKS_NAME exists in RG $AKS_RG_NAME"
  EXISTS_AKS=$(az aks list \
    --output json | jq -r ".[] | select( .name == \"$AKS_NAME\") | [.name] | @tsv" | wc -l)
}



##################
#
#    MAIN
#
#################


## Check Arguments
funcCheckArguments


## Check if AKS RG Exists
funcCheckRG


if [[ "$EXISTS_RG" == "0" ]]
then
  echo "RG $AKS_RG_NAME for $AKS_NAME does not exist"
  echo "Exiting"
  exit 3
elif [[ "$EXISTS_RG" == "1" ]]
then
  echo "RG $AKS_RG_NAME exists"
  echo "Continuing"
else
  echo "Some issue with the amount of RG"
  echo "Exiting"
  exit 3
fi	


## Check if AKS exist
funcCheckAKS

echo "Check if AKS exist"
if [[ "$EXISTS_AKS" != "1" ]]
then
  echo "AKS $AKS_NAME does not exist"
  echo "Exiting"
  exit 3
fi


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
