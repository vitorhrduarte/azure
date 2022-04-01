##!/usr/bin/env bash
set -e
. ./params.sh


## Get AKS Infra RG
echo "Getting AKS Infra RG"
AKS_INFRA_RG=$(az aks show \
    --resource-group $AKS_RG_NAME \
    --name $AKS_CLUSTER_NAME \
    --query nodeResourceGroup \
    --output tsv)

## Create Azure File Disk - Static
echo "Creating Azure File Disk - Static"
az disk create \
    --resource-group $AKS_INFRA_RG \
    --name $AKS_STATIC_DISK_NAME \
    --size-gb $AKS_STATIC_DISK_SIZE_IN_GB \
    --query id \
    --output tsv

## Get Disk ID
echo "Get $AKS_STATIC_DISK_NAME ID"
AKS_STATIC_DISK_ID=$(az disk list \
    --resource-group $AKS_INFRA_RG \
    --output json | jq --arg diskname $AKS_STATIC_DISK_NAME -r '.[] | select ( .name == $diskname )  | [.id] | @tsv')

## Remove the output file
echo "Removing sample-pod-with-static-disk.yaml"
rm -rf sample-pod-with-static-disk.yaml

## Generate Sample Pod Yaml
echo "Generating Sample Pod Yaml"
printf "apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
spec:
  containers:
  - image: $POD_IMAGE
    name: $POD_NAME
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 250m
        memory: 256Mi
    volumeMounts:
      - name: azure
        mountPath: /mnt/azure
  volumes:
      - name: azure
        azureDisk:
          kind: Managed
          diskName: $AKS_STATIC_DISK_NAME
          diskURI: $AKS_STATIC_DISK_ID
" >> sample-pod-with-static-disk.yaml

kubectl apply -f sample-pod-with-static-disk.yaml
