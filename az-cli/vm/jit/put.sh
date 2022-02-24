##!/usr/bin/env bash
set -e
. ./params.sh

## Get AZ VM RG
echo "Getting Az Vm RG"
AZ_VM_RG=$(az vm list -o json | jq -r ".[] | ( select( .name == \"$AZURE_VM\" )) | [ .resourceGroup ] | @tsv")

## Get AZ VM ID
echo "Getting Az Vm Id"
AZ_VM_ID=$(az vm show --resource-group $AZ_VM_RG --name $AZURE_VM --output json | jq -r "[.id] | @tsv")
AZ_SUB_ID=$(echo $AZ_VM_ID | cut -d \/ -f 3)

## Define VM Endpoint for Jit
echo "Define VM Endpoint for Jit"
AZ_VM_ENDPOINT="https://management.azure.com/subscriptions/$AZ_SUB_ID/resourceGroups/$AZ_VM_RG/providers/Microsoft.Security/locations/$AZURE_VM_LOCATION/jitNetworkAccessPolicies/$AZ_VM_JIT_POL_NAME?api-version=2020-01-01"

## Removing any existin Jit Json file
echo "Removing any existin Jit Json file"
rm -rf $AZURE_VM_JIT_CREATION_NAME 

## Create JIT Json file
echo "Create JIT Json file"
printf "
{
  "kind": \"Basic\",
  "properties": {
    "virtualMachines": [
      {
        "id": \"$AZ_VM_ID\",
        "ports": [
          {
            "number": \"$AZURE_VM_LINUX_PORT\",
            "protocol": \"*\",
            "allowedSourceAddressPrefix": \"$MY_ISP_IP\",
            "maxRequestAccessDuration": \"$AZURE_VM_JIT_DURATION\"
          }
        ]
      }
    ]
  }
}
" >> $AZURE_VM_JIT_CREATION_NAME

## Execute Curl
echo "Executing Curl Operation"
curl -v -H "authorization: bearer $AZURE_TOKEN" -H "content-type: application/json"  --request PUT --data @$AZURE_VM_JIT_CREATION_NAME "$AZ_VM_ENDPOINT"

