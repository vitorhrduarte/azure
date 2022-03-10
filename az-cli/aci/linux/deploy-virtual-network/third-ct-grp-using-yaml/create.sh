##!/usr/bin/env bash
set -e
. ./params.sh


## Create SubNet for ACI GRP 02
echo "Create SubNet for $ACI_SUBNET_NAME"
az network vnet subnet create \
  --resource-group $ACI_MAIN_VNET_RG \
  --vnet-name $ACI_MAIN_VNET_NAME \
  --name $ACI_SUBNET_NAME \
  --address-prefixes $ACI_SUBNET_CIDR \
  --debug


## Get SubNet ID
echo "Getting Subnet ID"
ACI_SNET_ID=$(az network vnet subnet show \
  --resource-group $ACI_MAIN_VNET_RG \
  --vnet-name $ACI_MAIN_VNET_NAME \
  --name $ACI_SUBNET_NAME \
  --query id -o tsv)

echo ""
echo $ACI_SNET_ID

## Add SubNet Delegation
echo "Add SubNet Delegation"
az network vnet subnet update \
  --resource-group $ACI_MAIN_VNET_RG \
  --name $ACI_SUBNET_NAME \
  --vnet-name $ACI_MAIN_VNET_NAME \
  --delegations Microsoft.ContainerInstance/containerGroups \
  --debug


## Remove any yaml file
echo "Remove any yaml file"
rm -rf $ACI_YAML_FILE_NAME

## Define ymail file
echo "Define yaml file"

printf "
apiVersion: '2021-07-01'
location: $ACI_MAIN_VNET_LOCATION
name: $ACI_GRP_NAME
properties:
  containers:
  - name: $ACI_GRP_NAME
    properties:
      image: $ACI_GRP_IMAGE
      ports:
      - port: $ACI_EXPOSE_PORT
        protocol: $ACI_USE_PROTOCOL
      resources:
        requests:
          cpu: $ACI_CPU_REQUEST
          memoryInGB: $ACI_MEM_REQUEST
  ipAddress:
    type: $ACI_IP_TYPE
    ports:
    - protocol: $ACI_USE_PROTOCOL
      port: $ACI_EXPOSE_PORT
  osType: Linux
  restartPolicy: Always
  subnetIds:
    - id: $ACI_SNET_ID
      name: $ACI_SUBNET_NAME
tags: null
type: Microsoft.ContainerInstance/containerGroups
" >> $ACI_YAML_FILE_NAME


## Deploy ACI
echo "Deploy ACI"
az container create \
  --resource-group $ACI_MAIN_VNET_RG \
  --file $ACI_YAML_FILE_NAME \
  --debug

