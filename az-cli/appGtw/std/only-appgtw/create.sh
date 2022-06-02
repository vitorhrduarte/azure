##!/usr/bin/env bash
set -e
. ./params.sh

## Create AppGtw Vnet
echo "Create AppGtw Vnet"
az network vnet subnet create \
  --name $APPGTW_SUBNET_NAME \
  --resource-group $APPGTW_RG_NAME \
  --vnet-name $APPGTW_MAIN_VNET_NAME \
  --address-prefixes $APPGTW_SUBNET_PREFIX \
  --debug

## Create Public IP for AppGtw
echo "Create public IP for AppGtw"
az network public-ip create \
  --resource-group $APPGTW_RG_NAME \
  --name $APPGTW_PUBLIC_IP_NAME \
  --allocation-method $APPGTW_PUBLIC_IP_ALLOCATION_METHOD \
  --sku $APPGTW_PUBLIC_IP_SKU \
  --debug

## Create AppGtw
echo "Deploy AppGtw"
az network application-gateway create \
  --resource-group $APPGTW_RG_NAME \
  --location $APPGTW_LOCATION \
  --name $APPGTW_NAME \
  --capacity $APPGTW_CAPACITY \
  --sku $APPGTW_SKU \
  --vnet-name $APPGTW_MAIN_VNET_NAME \
  --subnet $APPGTW_SUBNET_NAME \
  --public-ip-address $APPGTW_PUBLIC_IP_NAME \
  --priority 1 \
  --debug

echo "END"
