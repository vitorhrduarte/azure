##!/usr/bin/env bash

declare -a AKS_NP_ARRAY
declare -a AKS_ARRAY

## Get AKS
AKS_ARRAY=($(az aks list -o json | jq -r ".[] | [ .name, .resourceGroup ] | @csv"))

## Declare AKS Options List/Array
declare -a AKS_OPTIONS

## Show Array options
for i in ${!AKS_ARRAY[@]}
do
  AKS_OPTIONS+=(${AKS_ARRAY[$i]} $i)
done

## Define GUI Window - AKS
HEIGHT=30
WIDTH=60
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
AKS_NP_ARRAY=($(az aks nodepool list --resource-group ${TMP_AKS_CHOICE_ARRAY[1]} --cluster-name ${TMP_AKS_CHOICE_ARRAY[0]} --output json | jq -r '.[] | [ .name, .osType, .count, .resourceGroup ] | @csv'))

## Declare AKS Nodepool options List/Array
declare -a AKS_NP_OPTIONS

for i in ${!AKS_NP_ARRAY[@]}
do
  AKS_NP_OPTIONS+=(${AKS_NP_ARRAY[$i]} $i)
done

## Define GUI Window - VMSS
HEIGHT=30
WIDTH=60
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


## Parsing Choive
TMP_AKS_NP_CHOICE="${AKS_NP_CHOICE[0]}"
TMP_AKS_NP_CHOICE_ARRAY=($(echo $TMP_AKS_NP_CHOICE | tr -d '"' |tr "," "\n"))

## Prepare command
SSH_KEY_PUB=$(cat $ADMIN_USERNAME_SSH_KEYS_PUB)

## The default user in VMSS is the azureuser.
## If there is already another user, adapt accordingly

## Be default azureuser
VMSS_SSH_SUDO_USER=$GENERIC_ADMIN_USERNAME
VMSS_COMMAND="echo $SSH_KEY_PUB >> /home/$VMSS_SSH_SUDO_USER/.ssh/authorized_keys"

if [[ ${TMP_AKS_NP_CHOICE_ARRAY[1]} == "Linux" ]]; then
  echo "Linux nodepool founded"
  AKS_RG_NPOOL=$(az vmss list --output json | jq -r ".[] | [ .resourceGroup, .name, .tags.poolName ] | @csv" | grep -i ${TMP_AKS_NP_CHOICE_ARRAY[0]} | awk -F "," '{print $1}' | sed 's/"//g')  
  AKS_NPOOL_NAME=$(az vmss list --output json | jq -r ".[] | [ .resourceGroup, .name, .tags.poolName ] | @csv" | grep -i ${TMP_AKS_NP_CHOICE_ARRAY[0]} | awk -F "," '{print $2}' | sed 's/"//g')

  for (( i=0; i<${TMP_AKS_NP_CHOICE_ARRAY[2]}; i++ ))
  do
    echo "Processing instance # $i of $(expr ${TMP_AKS_NP_CHOICE_ARRAY[2]} - 1)"
   
    az vmss run-command invoke --resource-group $AKS_RG_NPOOL --name $AKS_NPOOL_NAME --command-id RunShellScript  \
      --instance-id $i --command-id RunShellScript --scripts "$VMSS_COMMAND" 2&>1
  done
else
  if [[ ${TMP_AKS_NP_CHOICE_ARRAY[1]} == "Windows" ]]; then
    echo "Windows nodepool founded"
    echo "Processing instance # $i of $(expr ${TMP_AKS_NP_CHOICE_ARRAY[2]} - 1)"

    AKS_RG_NPOOL=$(az vmss list --output json | jq -r ".[] | [ .resourceGroup, .name, .tags.poolName ] | @csv" | grep -i ${TMP_AKS_NP_CHOICE_ARRAY[0]} | awk -F "," '{print $1}' | sed 's/"//g')      
    AKS_NPOOL_NAME=$(az vmss list --output json | jq -r ".[] | [ .resourceGroup, .name, .tags.poolName ] | @csv" | grep -i ${TMP_AKS_NP_CHOICE_ARRAY[0]} | awk -F "," '{print $2}' | sed 's/"//g')   

    for (( i=0; i<${TMP_AKS_NP_CHOICE_ARRAY[2]}; i++ )) 
    do
      az vmss run-command invoke --command-id RunPowerShellScript --name aksnpwin --resource-group $AKS_RG_NPOOL \
        --scripts '$sp = ConvertTo-SecureString "P@ssword!123" -AsPlainText -Force; New-LocalUser -Password $sp -Name "tmp-gits"; Add-LocalGroupMember -Group Administrators -Member "tmp-gits"' \
        --instance-id $i
    done
  fi
fi


