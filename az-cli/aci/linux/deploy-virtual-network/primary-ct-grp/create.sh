##!/usr/bin/env bash
set -e
. ./params.sh


## Create RG
echo "Create RG"
az group create \
  --name $ACI_MAIN_VNET_RG \
  --location $ACI_MAIN_VNET_LOCATION \
  --debug


## Create VNet
echo "Create Vnet for $ACI_MAIN_VNET_NAME"
az network vnet create \
  --resource-group $ACI_MAIN_VNET_RG \
  --name $ACI_MAIN_VNET_NAME \
  --address-prefix $ACI_MAIN_VNET_CIDR \
  --debug


## Create SubNet for ACI
echo "Create SubNet for $ACI_SUBNET_NAME"
az network vnet subnet create \
  --resource-group $ACI_MAIN_VNET_RG \
  --vnet-name $ACI_MAIN_VNET_NAME \
  --name $ACI_SUBNET_NAME \
  --address-prefixes $ACI_SUBNET_CIDR \
  --debug

## Create Container Group
echo "Create Container Group"
az container create \
  --name $ACI_CONT_GRP_NAME \
  --resource-group $ACI_MAIN_VNET_RG \
  --image $ACI_CONT_GRP_IMAGE \
  --vnet $ACI_MAIN_VNET_NAME \
  --vnet-address-prefix $ACI_MAIN_VNET_CIDR \
  --subnet $ACI_SUBNET_NAME \
  --subnet-address-prefix $ACI_SUBNET_CIDR \
  --debug
