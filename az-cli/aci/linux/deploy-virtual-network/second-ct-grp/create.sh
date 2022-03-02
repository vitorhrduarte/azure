##!/usr/bin/env bash
set -e
. ./params.sh

## Get Current Az Cont Group Priv IP
echo "Get Current Az Cont Group Priv IP"
AZ_CT_GRP01_PRIV_IP=$(az container show --resource-group $ACI_MAIN_VNET_RG --name $ACI_CONT_GRP_01_NAME --query ipAddress.ip --output tsv)

## Output IP
echo "Output IP"
echo $AZ_CT_GRP01_PRIV_IP


## Create Second Container Group in Same SubNet
echo "Create Second Container Group in Same SubNet"
az container create \
  --name $ACI_CONT_GRP_02_NAME \
  --resource-group $ACI_MAIN_VNET_RG \
  --image $ACI_CONT_GRP_02_IMAGE \
  --command-line "wget $AZ_CT_GRP01_PRIV_IP" \
  --restart-policy never \
  --vnet $ACI_MAIN_VNET_NAME \
  --subnet $ACI_SUBNET_NAME \
  --debug
