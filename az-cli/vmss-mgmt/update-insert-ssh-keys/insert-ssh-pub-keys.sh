##!/usr/bin/env bash

declare -a VMSS_ARRAY
declare -a AKS_ARRAY

## Get AKS
AKS_ARRAY=($(az aks list -o json | jq -r ".[] | [ .name, .nodeResourceGroup, .resourceGroup ] | @csv"))

## Declare AKS Options List/Array
#echo "Declaring AKS Options Array"
declare -a AKS_OPTIONS
#echo "Process AKS Options List"
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

## Get VMSS 
VMSS_ARRAY=($(az vmss list -o json | jq -r ".[] | [ .name, .resourceGroup ] | @tsv" | grep -i  ${TMP_AKS_CHOICE_ARRAY[1]} | awk '{print $1}'))

## Declare Options List/Array
#echo "Declaring VMSS Options Array"
declare -a VMSS_OPTIONS
#echo "Process VMSS Options List"
for i in ${!VMSS_ARRAY[@]}
do
  VMSS_OPTIONS+=(${VMSS_ARRAY[$i]} $i)
done

## Define GUI Window - VMSS
HEIGHT=30
WIDTH=60
CHOICE_HEIGHT=10
BACKTITLE="VMSS Details"
TITLE="Choose VMSS"
MENU="Choose one of the following options:"

## Define User Choice
VMSS_CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${VMSS_OPTIONS[@]}" \
                2>&1 >/dev/tty)


## Parsing Choive
OPTIONS_SPLITTED="${AKS_CHOICE[0]},${VMSS_CHOICE[0]}"
OPTIONS_SPLITTED_ARRAY=($(echo $OPTIONS_SPLITTED | tr -d '"' |tr "," "\n"))

## Prepare command
SSH_KEY_PUB=$(cat $ADMIN_USERNAME_SSH_KEYS_PUB)

## The default user in VMSS is the azureuser.
## If there is already another user, adapt accordingly
VMSS_COMMAND="echo $SSH_KEY_PUB >> /home/azureuser/.ssh/authorized_keys"

## Get AKS nodepood IDS
AKS_ARRAY_INST_IDS=($(az aks show -n ${OPTIONS_SPLITTED_ARRAY[0]} -g ${OPTIONS_SPLITTED_ARRAY[2]} --query id -o tsv))

j=0
for i in ${AKS_ARRAY_INST_IDS[@]}
do
  az vmss run-command invoke -g ${OPTIONS_SPLITTED_ARRAY[1]} -n ${OPTIONS_SPLITTED_ARRAY[3]} --command-id RunShellScript  --instance-id $j --command-id RunShellScript --scripts "$VMSS_COMMAND" 2&>1
  ((j=j+1)) 
done



