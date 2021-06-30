##!/usr/bin/env bash

showHelp() {
cat << EOF  
Usage: 

bash delete-vm.sh --help/-h  [for help]
bash delete-vm.sh -g/--rgroup <resource-group-name> -r/--role <vm-role-tag>

Install Pre-requisites jq and dialog

-h, -help,          --help                  Display help

-g, -g,             --rgroup                Resource Group where the VM's are

-r, -role,          --role                  VM Role Tag to be deleted

EOF
}

options=$(getopt -l "help::,rgroup:,role:" -o "h::g:r:" -a -- "$@")

eval set -- "$options"

while true
do
case $1 in
-h|--help) 
    showHelp
    exit 0
    ;;  
-g|--rgroup)
    shift
    RG=$1
    ;;  
-r|--role)
    shift
    ROLE=$1
    ;;  
--)
    shift
    break
    exit 0    
    ;;  
esac
shift
done


## Deleting VM's
echo "Deleting VM's"
az vm list -o json | jq --arg rg $RG --arg role $ROLE '.[] | select(.resourceGroup | test($rg;"i")) | select(.tags.role == $role) | [ .id ] | @tsv' | xargs az vm delete --no-wait --yes --debug --ids

## Need to wait for all VM deletion to proceed to NIC deletion
echo "Checking VM's deletion process"
COUNTER_VM=$(az vm list -o json | jq --arg rg $RG --arg role $ROLE '.[] | select( .tags.role == $role and .resourceGroup == $rg) | [ .id ] | @tsv' | wc -l)

while [[ $COUNTER_VM != "0" ]]
do
  sleep 15  
  COUNTER_VM=$(az vm list -o json | jq --arg rg $RG --arg role $ROLE '.[] | select( .tags.role == $role and .resourceGroup == $rg) | [ .id ] | @tsv' | wc -l)
  echo "Current #VM's : $COUNTER_VM"
  echo "Waiting for VM's deletion..."
done

## Deleting VM's NICs
echo "Delete VM's NICs"
az network nic list -o json | jq --arg rg $RG --arg role $ROLE '.[] | select(.resourceGroup | test($rg;"i")) | select(.tags.role == $role) | [ .id ] | @tsv' | xargs az network nic delete --no-wait --debug --ids

## Deleting VM's Disks
echo "Delete VM's Disks"
az disk list -o json | jq --arg rg $RG --arg role $ROLE '.[] | select(.resourceGroup | test($rg;"i")) | select(.tags.role == $role) | [ .id ] | @tsv' | xargs az disk delete --no-wait --yes --debug --ids


## Delete NSG
echo "Delete NSG's"
az network nsg list -o json  | jq --arg rg $RG --arg role $ROLE '.[] | select(.resourceGroup | test($rg;"i")) | select(.tags.role == $role) | [ .id ] | @tsv' | xargs az network nsg delete --debug --ids


