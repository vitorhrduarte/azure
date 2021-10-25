##!/usr/bin/env bash

# Generic Vars
rg="rg-aci"
rg_location="westeurope"
containerName="aci-demo"
containerImage="mcr.microsoft.com/azuredocs/aci-helloworld"
containerListenPort="80"


# Random String Generator
lenghtString=12
ranString=$(tr -dc a-z </dev/urandom | head -c $lenghtString)

## Create RG for ACI
echo "Create RG for ACI"
az group create \
  --name $rg \
  --location $rg_location \
  --debug


echo ""
echo "Create Container"
az container create \
--resource-group $rg \
--name $containerName \
--image $containerImage \
--dns-name-label $ranString \
--ports $containerListenPort

echo ""
echo "Output Specs.."
az container show \
--resource-group $rg \
--name $containerName \
--query "{PublicIP:ipAddress.ip,FQDN:ipAddress.fqdn,ProvisioningState:provisioningState}" \
--out table
