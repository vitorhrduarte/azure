##!/usr/bin/env bash
set -e
. ./params.sh

## Create NMAP TCP RG
echo "Create NMAP TCP RG"
az group create \
  --name $ACI_RG \
  --location $ACI_RG_LOCATION \
  --debug



## Remove any yaml file
echo "Remove any yaml file"
rm -rf $ACI_YAML_FILE_NAME

## Define ymail file
echo "Define yaml file"

printf "
apiVersion: '2021-07-01'
location: $ACI_RG_LOCATION
name: $ACI_GRP_NAME
properties:
  containers:
  - name: $ACI_GRP_NAME
    properties:
      image: $ACI_GRP_IMAGE
      command: [ "nmap", "-v", "-p-", "-Pn", "1.1.1.1" ]
      resources:
        requests:
          cpu: $ACI_CPU_REQUEST
          memoryInGB: $ACI_MEM_REQUEST
  osType: Linux
  restartPolicy: Always
tags: null
type: Microsoft.ContainerInstance/containerGroups
" >> $ACI_YAML_FILE_NAME


## Deploy ACI
echo "Deploy ACI"
az container create \
  --resource-group $ACI_RG \
  --file $ACI_YAML_FILE_NAME \
  --debug

