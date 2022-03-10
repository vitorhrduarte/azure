##!/usr/bin/env bash
set -e
. ./params.sh

## Create RG for KV
echo "Create RG for KV"
az group create \
  --name $KV_RG_NAME \
  --location $KV_RG_LOCATION \
  --debug

## Create KV
echo "Create KV"
az keyvault create \
  --name $KV_UNIQ_NAME \
  --resource-group $KV_RG_NAME \
  --location $KV_RG_LOCATION \
  --debug
