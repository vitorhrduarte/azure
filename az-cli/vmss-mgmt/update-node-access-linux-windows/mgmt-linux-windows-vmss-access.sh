##!/usr/bin/env bash

###############################
# Arrays - Start
###############################

declare -a AKS_NP_ARRAY
declare -a AKS_VMSS_NP_DETAILS
declare -a AKS_ARRAY
declare -a AKS_NP_INSTANCE_ID

################################
# Arrays - End
################################

################################
# Functions - Start
################################

function getVmssNpDetails () {
  local NP_DETAILS=$1
 
  AKS_RG_NPOOL=$(az vmss list --output json | jq --arg nprn $NP_DETAILS -r '.[] | select( .tags.poolName == $nprn ) | [ .resourceGroup ] | @csv' | sed 's/"//g')
  AKS_NPOOL_NAME=$(az vmss list --output json | jq --arg npn $NP_DETAILS -r '.[] | select( .tags.poolName == $npn ) | [ .name ] | @csv'  | sed 's/"//g')
}

function processVmssWindows () {
  local FUNC_VMSS_ID=$1 
  local FUNC_NP_NAME=$2
  local FUNC_RG_NP=$3
 
  az vmss run-command invoke --command-id RunPowerShellScript --name $FUNC_NP_NAME --resource-group $FUNC_RG_NP \
    --scripts '$sp = ConvertTo-SecureString "P@ssword!123" -AsPlainText -Force; New-LocalUser -Password $sp -Name "tmp-gits"; Add-LocalGroupMember -Group Administrators -Member "tmp-gits"' \
    --instance-id $FUNC_VMSS_ID
}

function processVmssLinux () {
  local FUNC_VMSS_ID=$1
  local FUNC_NP_NAME=$2
  local FUNC_RG_NP=$3

  az vmss run-command invoke --resource-group $FUNC_RG_NP --name $FUNC_NP_NAME --command-id RunShellScript  \
    --instance-id $FUNC_VMSS_ID --command-id RunShellScript --scripts "$VMSS_COMMAND"
}

function npIds () {
  local FUNC_NP_NAME=$1
  local FUNC_RG_NP=$2
 
  TMP_NP_IDS=($(az vmss list-instances \
     --resource-group $FUNC_RG_NP \
     --name $FUNC_NP_NAME --output json | jq -r ".[] | [ .instanceId] | @csv" | sed 's/"//g'))
}

###############################
# Functions - End
###############################

## Get AKS
AKS_ARRAY=($(az aks list \
  --output json | jq -r ".[] | [ .name, .resourceGroup, .nodeResourceGroup ] | @csv"))

## Declare AKS Options List/Array
declare -a AKS_OPTIONS

## Show Array options
for i in ${!AKS_ARRAY[@]}
do
  AKS_OPTIONS+=(${AKS_ARRAY[$i]} $i)
done

## Define GUI Window - AKS
HEIGHT=30
WIDTH=100
CHOICE_HEIGHT=10
BACKTITLE="AKS Details"
TITLE="Choose AKS"
MENU="Choose one of the following options:"

## Define User Choice
AKS_CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${AKS_OPTIONS[@]}" \
                2>&1 >/dev/tty)

## Parsing Choice
TMP_AKS_CHOICE=${AKS_CHOICE[0]}
TMP_AKS_CHOICE_ARRAY=($(echo $TMP_AKS_CHOICE | tr -d '"' |tr "," "\n"))

## Get AKS nodepool
AKS_NP_ARRAY=($(az aks nodepool list \
  --resource-group ${TMP_AKS_CHOICE_ARRAY[1]} \
  --cluster-name ${TMP_AKS_CHOICE_ARRAY[0]} \
  --output json | jq -r '.[] | [ .name, .osType, .count, .resourceGroup ] | @csv'))

## Declare AKS Nodepool options List/Array
declare -a AKS_NP_OPTIONS

for i in ${!AKS_NP_ARRAY[@]}
do
  AKS_NP_OPTIONS+=(${AKS_NP_ARRAY[$i]} $i)
done

## Define GUI Window - VMSS
HEIGHT=30
WIDTH=100
CHOICE_HEIGHT=10
BACKTITLE="VMSS Details"
TITLE="Choose VMSS"
MENU="Choose one of the following options:"

## Define User Choice
AKS_NP_CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${AKS_NP_OPTIONS[@]}" \
                2>&1 >/dev/tty)

## Parsing Choice
TMP_AKS_NP_CHOICE="${AKS_NP_CHOICE[0]}"
TMP_AKS_NP_CHOICE_ARRAY=($(echo $TMP_AKS_NP_CHOICE | tr -d '"' |tr "," "\n"))

## Be default azureuser
VMSS_SSH_SUDO_USER=$GENERIC_ADMIN_USERNAME
VMSS_SSH_PUB_KEY=$(cat $ADMIN_USERNAME_SSH_KEYS_PUB)
VMSS_COMMAND="echo $VMSS_SSH_PUB_KEY >> /home/$VMSS_SSH_SUDO_USER/.ssh/authorized_keys"

if [ ${TMP_AKS_NP_CHOICE_ARRAY[2]} -gt 1 ]; then
  echo "Nodepool with more than 1 Instance..."
  PS3='Perform action in All(1) instances or just One(2) specific: '
  select result in 'All' 'One'; do
    case $REPLY in
        [12])
            break
            ;;
        *)
            echo 'Invalid choice' >&2
    esac
  done  

  if [[ "$REPLY" == "2" ]]; then
    echo "Processing one ID"
    ## Get AKS VMSS Nodepool details
    AKS_VMSS_NP_DETAILS=($(az vmss list --resource-group ${TMP_AKS_CHOICE_ARRAY[2]} \
      --output json | jq --arg npn ${TMP_AKS_NP_CHOICE_ARRAY[0]} -r '.[] | select( .tags.poolName == $npn  )  | [ .name, .resourceGroup, .tags.poolName ] | @csv'))

    ## Declare AKS Nodepool options List/Array
    declare -a AKS_VMSS_NP_OPTIONS

    for i in ${!AKS_VMSS_NP_DETAILS[@]}
    do
      AKS_VMSS_NP_OPTIONS+=(${AKS_VMSS_NP_DETAILS[$i]} $i)
    done
 
    ## Define GUI Window - VMSS nodepool details
    HEIGHT=30
    WIDTH=100
    CHOICE_HEIGHT=10
    BACKTITLE="VMSS Nodepool Details"
    TITLE="Confirm VMSS Nodepool"
    MENU="Confirm following option:"
 
    ## Define User Choice
    AKS_VMSS_NP_CHOICE=$(dialog --clear \
                 --backtitle "$BACKTITLE" \
                 --title "$TITLE" \
                 --menu "$MENU" \
                 $HEIGHT $WIDTH $CHOICE_HEIGHT \
                 "${AKS_VMSS_NP_OPTIONS[@]}" \
                 2>&1 >/dev/tty)
 
    ## Parsing Choice
    TMP_AKS_VMSS_NP_CHOICE="${AKS_VMSS_NP_CHOICE[0]}"
    TMP_AKS_VMSS_NP_CHOICE_ARRAY=($(echo $TMP_AKS_VMSS_NP_CHOICE | tr -d '"' |tr "," "\n"))

    ## Get AKS VMSS Nodepool Instances    
    AKS_NP_INSTANCE_ID=($(az vmss list-instances --resource-group ${TMP_AKS_VMSS_NP_CHOICE_ARRAY[1]} \
      --name ${TMP_AKS_VMSS_NP_CHOICE_ARRAY[0]} \
      --output json | jq -r ".[] | [ .instanceId, .name, .resourceGroup ] | @csv"))

    ## Declare AKS Options List/Array
    declare -a AKS_INSTANCE_OPTIONS
 
    ## Show Array options
    for i in ${!AKS_NP_INSTANCE_ID[@]}
    do
      AKS_INSTANCE_OPTIONS+=(${AKS_NP_INSTANCE_ID[$i]} $i)
    done
 
    ## Define GUI Window - AKS Nodepool IDS
    HEIGHT=30
    WIDTH=100
    CHOICE_HEIGHT=10
    BACKTITLE="AKS Nodepool Instance Details"
    TITLE="Choose AKS Nodepool Instance ID"
    MENU="Choose one of the following options:"
 
    ## Define User Choice
    AKS_INSTANCE_CHOICE=$(dialog --clear \
                 --backtitle "$BACKTITLE" \
                 --title "$TITLE" \
                 --menu "$MENU" \
                 $HEIGHT $WIDTH $CHOICE_HEIGHT \
                 "${AKS_INSTANCE_OPTIONS[@]}" \
                 2>&1 >/dev/tty)
 
    ## Parsing Choice
    TMP_AKS_INSTANCE_CHOICE=${AKS_INSTANCE_CHOICE[0]}
    TMP_AKS_INSTANCE_CHOICE_ARRAY=($(echo $TMP_AKS_INSTANCE_CHOICE | tr -d '"' |tr "," "\n"))
 
    if [[ ${TMP_AKS_NP_CHOICE_ARRAY[1]} == "Linux" ]]; then
      echo "Linux nodepool founded"
      echo "Processing instance # ${TMP_AKS_INSTANCE_CHOICE_ARRAY[0]}"
      getVmssNpDetails ${TMP_AKS_NP_CHOICE_ARRAY[0]}
      processVmssLinux ${TMP_AKS_INSTANCE_CHOICE_ARRAY[0]} $AKS_NPOOL_NAME $AKS_RG_NPOOL

    elif [[ ${TMP_AKS_NP_CHOICE_ARRAY[1]} == "Windows" ]]; then
      echo "Windows nodepool founded"
      echo "Processing instance # ${TMP_AKS_INSTANCE_CHOICE_ARRAY[0]}"
      getVmssNpDetails ${TMP_AKS_NP_CHOICE_ARRAY[0]}
      processVmssWindows ${TMP_AKS_INSTANCE_CHOICE_ARRAY[0]} $AKS_NPOOL_NAME $AKS_RG_NPOOL 

    fi
  elif [[ "$REPLY" == "1"  ]]; then
    echo "Perform action in ALL ids"
    if [[ ${TMP_AKS_NP_CHOICE_ARRAY[1]} == "Linux" ]]; then
      echo "Linux nodepool founded"
      getVmssNpDetails ${TMP_AKS_NP_CHOICE_ARRAY[0]}
      npIds $AKS_NPOOL_NAME $AKS_RG_NPOOL

      for i in "${TMP_NP_IDS[@]}"
      do
        echo "Processing instance ID = $i"
        processVmssLinux $i $AKS_NPOOL_NAME $AKS_RG_NPOOL
      done
    elif [[ ${TMP_AKS_NP_CHOICE_ARRAY[1]} == "Windows" ]]; then
      echo "Windows nodepool founded"
      getVmssNpDetails ${TMP_AKS_NP_CHOICE_ARRAY[0]}
      npIds $AKS_NPOOL_NAME $AKS_RG_NPOOL

      for i in "${TMP_NP_IDS[@]}"
      do
        echo "Processing instance ID = $i"
        processVmssWindows $i $AKS_NPOOL_NAME $AKS_RG_NPOOL
      done
    fi      
  fi
else
  echo "Perform action in ALL instance ids of the select nodepool"
  if [[ ${TMP_AKS_NP_CHOICE_ARRAY[1]} == "Linux" ]]; then
    echo "Linux nodepool founded"
    getVmssNpDetails ${TMP_AKS_NP_CHOICE_ARRAY[0]}
    npIds $AKS_NPOOL_NAME  $AKS_RG_NPOOL
 
    for i in "${TMP_NP_IDS[@]}"
    do
      echo "Processing instance ID = $i"
      processVmssLinux $i $AKS_NPOOL_NAME $AKS_RG_NPOOL
    done
  elif [[ ${TMP_AKS_NP_CHOICE_ARRAY[1]} == "Windows" ]]; then
    echo "Windows nodepool founded"
    getVmssNpDetails ${TMP_AKS_NP_CHOICE_ARRAY[0]}
    npIds $AKS_NPOOL_NAME  $AKS_RG_NPOOL

    for i in "${TMP_NP_IDS[@]}"
    do
      echo "Processing instance ID = $i"
      processVmssWindows $i $AKS_NPOOL_NAME $AKS_RG_NPOOL
    done
  fi
fi  

