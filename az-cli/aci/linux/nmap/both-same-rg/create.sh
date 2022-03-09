##!/usr/bin/env bash
set -e
. ./params.sh

## Create NMAP UDP/TCP RG
echo "Create NMAP UDP/TCP RG"
az group create \
  --name $ACI_RG \
  --location $ACI_RG_LOCATION \
  --debug


## Remove any yaml UDP file
echo "Remove any yaml UDP file"
rm -rf $ACI_UDP_YAML_FILE_NAME


## Remove any yaml TCP file
echo "Remove any yaml TCP file"
rm -rf $ACI_TCP_YAML_FILE_NAME


## Define UDP Yaml file
echo "Define UDP yaml file"

printf "
apiVersion: '2021-07-01'
location: $ACI_RG_LOCATION
name: $ACI_UDP_GRP_NAME
properties:
  containers:
  - name: $ACI_UDP_GRP_NAME
    properties:
      image: $ACI_UDP_GRP_IMAGE
      command: [ "nmap", "-sU", "--max-rtt-timeout", "100ms", "--max-retries", "1", "--max-scan-delay", "10ms", "--version-intensity", "0", "-v", "-p-", "-Pn", "1.1.1.1" ]
      resources:
        requests:
          cpu: $ACI_UDP_CPU_REQUEST
          memoryInGB: $ACI_UDP_MEM_REQUEST
  osType: Linux
  restartPolicy: Never
tags: null
type: Microsoft.ContainerInstance/containerGroups
" >> $ACI_UDP_YAML_FILE_NAME


## Define TCP Yaml file
echo "Define TCP yaml file"

printf "
apiVersion: '2021-07-01'
location: $ACI_RG_LOCATION
name: $ACI_TCP_GRP_NAME
properties:
  containers:
  - name: $ACI_TCP_GRP_NAME
    properties:
      image: $ACI_TCP_GRP_IMAGE
      command: [ "nmap", "-v", "-p-", "-Pn", "1.1.1.1" ]
      resources:
        requests:
          cpu: $ACI_TCP_CPU_REQUEST
          memoryInGB: $ACI_TCP_MEM_REQUEST
  osType: Linux
  restartPolicy: Always
tags: null
type: Microsoft.ContainerInstance/containerGroups
" >> $ACI_TCP_YAML_FILE_NAME


## Deploy ACI NMAP TCP
echo "Deploy NMAP TCP ACI"
az container create \
  --resource-group $ACI_RG \
  --file $ACI_TCP_YAML_FILE_NAME \
  --debug


## Deploy ACI NMAP UDP
echo "Deploy NMAP UDP ACI"
az container create \
  --resource-group $ACI_RG \
  --file $ACI_UDP_YAML_FILE_NAME \
  --debug

