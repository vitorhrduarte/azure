##!/usr/bin/env bash
set -e
. ./params.sh


## Create Subnet for AppGtw
echo "Create AppGtw Snet"
az network vnet subnet create \
  --resource-group $AKS_RG_NAME \
  --vnet-name $AKS_VNET_NAME \
  --name $APPTGTW_SNET_NAME \
  --address-prefixes $APPGTW_SNET_CIDR \
  --debug


## Enable the Addon
echo "Enable AppGtw"
az aks enable-addons \
  --name $AKS_NAME \
  --resource-group $AKS_RG_NAME \
  --addons ingress-appgw \
  --appgw-subnet-cidr $$APPGTW_SNET_CIDR \
  --appgw-name $APPGTW_NAME \
  --debug
