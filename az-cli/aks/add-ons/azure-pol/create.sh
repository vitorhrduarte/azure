#!/bin/bash


showHelp() {
cat << EOF  
Usage: 

bash create.sh --help/-h  [for help]
bash create.sh -o/--operation <enable disable> -n/--name <aks-name> -g/--group <aks-rg-name>

Install Pre-requisites jq

-h, -help,          --help                  Display help

-o, -operation,     --operation             Set operation type for the AKS cluster
                                            enable or disable AZ Pol from AKS

-n, -name,          --name                  AKS Name			

-g, -group,         --group                 AKS RG Group Name

EOF
}

options=$(getopt -l "help::,operation:,name:,group:" -o "h::o:n:g:" -a -- "$@")

eval set -- "$options"

while true
do
case $1 in
-h|--help) 
    showHelp
    exit 0
    ;;  
-o|--operation)
    shift
    AKS_OPERATION_TYPE=$1
    ;;  
-n|--name)
    shift
    AKS_NAME=$1
    ;;
-g|--group)
    shift
    AKS_RG=$1
    ;;
--)
    shift
    break
    exit 0    
    ;;  
esac
shift
done



OPER_TYPE=("enable" "disable")

containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

containsElement $AKS_OPERATION_TYPE "${OPER_TYPE[@]}" 
EXIST_OPT=$(echo $?)


if [[ $EXIST_OPT == "0" ]]; then
  echo "Operation Found... continue..."

  if [[ $oper == "enable" ]]; then
    echo "Enable AZ Pol"
    break
  elif [[ $oper = "disable" ]]; then
    echo "Disable AZ Pol"
    break
  fi
else
  echo "No valid option inserted..."
  echo "Exiting Program...."
  exit
fi

aksExist() {
  ## Verify if AKS exists in RG
  echo "Verify if AKS exists in RG"
  EXIST=$(az aks list -o json | jq -re ".[].name | select(. == \"$AKS_NAME\")" | wc -l)
}


enableAzPol() {
  ## Enable Az Pol
  echo "Enable Az Pol"
  az aks enable-addons \
    --addons azure-policy \
    --name $AKS_NAME \
    --resource-group $AKS_RG
}

disableAzPol() {
  ## Disable Az Pol
  echo "Disable Az Pol"
  az aks disable-addons \
    --addons azure-policy \
    --name $AKS_NAME \
    --resource-group $AKS_RG
}


######################################
##
##   Main Code
##
######################################

aksExist

if [[ $EXIST == "1" ]];
then
  ## AKS cluster exist!
  echo "AKS cluster exist!"
else
  ## AKS Cluster do not exist
  echo "AKS Cluster do not exist"
  exit
fi

if [[ $AKS_OPERATION_TYPE == "enable" ]];
then
  ## Enable AZ Pol
  echo "Enable AZ Pol"
  enableAzPol
elif [[ $AKS_OPERATION_TYPE == "disable" ]];
then
  ## Disable AZ Pol
  echo "Disable AZ Pol"
  disableAzPol
else
  ## No valid option
  echo "No valid option"
  exit
fi


