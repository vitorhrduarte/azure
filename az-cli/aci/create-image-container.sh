##!/usr/bin/env bash

# Generic Vars
containerName="aci-nd01"
rg="rg-"$containerName
rg_location="westeurope"
#containerImage="typeoneg/ubuntudebug:latest"
containerImage="typeoneg/netdebug:latest"

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
  --command-line "sleep infinity" \
  --restart-policy Never \
  --debug

