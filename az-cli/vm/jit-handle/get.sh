##!/usr/bin/env bash
set -e
. ./params.sh

## Get AZ VM RG
echo "Get AZ VM RG"
AZ_VM_RG=$(az vm list -o json | jq -r ".[] | ( select( .name == \"$AZURE_VM\" )) | [ .resourceGroup ] | @tsv")

## Get AZ VM ID
echo "Get AZ VM ID"
AZ_VM_ID=$(az vm show --resource-group $AZ_VM_RG --name $AZURE_VM --output json | jq -r "[.id] | @tsv")

## Get SUB ID
echo "Get SUB ID"
AZ_SUB_ID=$(echo $AZ_VM_ID | cut -d \/ -f 3)

AZ_VM_ENDPOINT="https://management.azure.com/subscriptions/$AZ_SUB_ID/resourceGroups/$AZ_VM_RG/providers/Microsoft.Security/jitNetworkAccessPolicies?api-version=2020-01-01"

JQ_STRING=".properties.virtualMachines[].id, \
.name, \
.properties.virtualMachines[].ports[].maxRequestAccessDuration, \
.properties.virtualMachines[].ports[].number, \
.properties.virtualMachines[].ports[].allowedSourceAddressPrefix"

echo ""
echo "All Details: "
curl -sL -H "authorization: bearer $AZURE_TOKEN" -H "contenttype: application/json" "$AZ_VM_ENDPOINT" | jq ".value"

echo ""
echo ""
echo "Just Relevant Information: "
curl -sL -H "authorization: bearer $AZURE_TOKEN" -H "contenttype: application/json" "$AZ_VM_ENDPOINT" | \
    jq -r ".value[] | [ $JQ_STRING ] | @tsv" | column -t  


