##!/usr/bin/env bash
set -e
. ./params.sh


az container delete \
  --resource-group $ACI_MAIN_VNET_RG \
  --name $ACI_CONT_GRP_01_NAME \
  --yes


az container delete \
  --resource-group $ACI_MAIN_VNET_RG \
  --name $ACI_CONT_GRP_02_NAME \
  --yes


az container delete \
  --resource-group $ACI_MAIN_VNET_RG \
  --name $ACI_CONT_GRP_03_NAME \
  --yes

# Get network profile ID
# Assumes one profile in virtual network
NETWORK_PROFILE_ID=$(az network profile list --resource-group $ACI_MAIN_VNET_RG --query [0].id --output tsv)

# Delete the network profile
az network profile delete \
  --id $NETWORK_PROFILE_ID \
  --yes

# Delete virtual network
az network vnet delete \
  --resource-group $ACI_MAIN_VNET_RG \
  --name $ACI_MAIN_VNET_NAME
