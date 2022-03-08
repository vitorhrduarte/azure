##!/usr/bin/env bash
set -e
. ./params.sh

## Create RG for Log Analytics WorkSpace
echo "Create RG for Log AWSpace"
az group create \
  --name $LOG_RG_NAME \
  --location $LOG_RG_LOCATION \
  --debug

## Create Log Analytics WorkSpace
echo "Creating LAWSpace"
az monitor log-analytics workspace create \
  --resource-group $LOG_RG_NAME \
  --workspace-name $LOG_WKS_NAME \
  --location $LOG_RG_LOCATION \
  --sku $LOG_SKU \
  --debug 

## Get LAWSpace details
echo "Getting LAWSpace Details"
LAWS_ID=$(az monitor log-analytics workspace list \
  --output json | jq -r ".[] |  select ( .name == \"$LOG_WKS_NAME\"  ) | [ .customerId ] | @csv")

LAWS_KEY=$(az monitor log-analytics workspace get-shared-keys \
  --resource-group $LOG_RG_NAME \
  --workspace-name $LOG_WKS_NAME | jq -r ".primarySharedKey")

## ACI Group Create Just Check if it is Working
echo "Create Container Group 01 - Am I alone here"
az container create \
  --resource-group $LOG_RG_NAME \
  --name $ACI_CONTAINER_NAME_01 \
  --image $ACI_CONTAINER_IMAGE_01 \
  --dns-name-label $ACI_CONTAINER_DNS_LABEL_01 \
  --ports $ACI_CONTAINER_LISTENING_PORT_01 \
  --log-analytics-workspace $LAWS_ID \
  --log-analytics-workspace-key $LAWS_KEY \
  --debug

## ACI Group Check Logging
echo "Create Container Group 01 - Logging Solution"
az container create \
  --resource-group $LOG_RG_NAME \
  --name $ACI_CONTAINER_NAME_02 \
  --image $ACI_CONTAINER_IMAGE_02 \
  --dns-name-label $ACI_CONTAINER_DNS_LABEL_02 \
  --log-analytics-workspace $LAWS_ID \
  --log-analytics-workspace-key $LAWS_KEY \
  --debug

## Output ACI Specs
echo "Output Specs.. for CG - 01"
az container show \
  --resource-group $LOG_RG_NAME \
  --name $ACI_CONTAINER_NAME_01  \
  --query "{PublicIP:ipAddress.ip,FQDN:ipAddress.fqdn,ProvisioningState:provisioningState}" \
  --out table

echo "END"
