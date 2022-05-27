#!/bin/bash



showHelp() {
cat << EOF  
Usage: 

bash go.sh --help/-h  [for help]
bash go.sh -p/--pod <pod-name> -t/--tag <nodepool-instance-tag-namep-host-name> 

Install Pre-requisites JQ

-h, -help,          --help                  Display help

-p, -pod,           --pod                   Define pod name

-t, -tag,           --tag                   Define, if we want, if defined, deploy pod in a
                                            specific nodepool instance          
EOF
}

options=$(getopt -l "help::,pod:,tag:" -o "h::p:t:" -a -- "$@")

eval set -- "$options"


while true
do
case $1 in
-h|--help) 
    showHelp
    exit 0
    ;;  
-p|--pod)
    shift
    POD_NAME=$1
    ;;  
-t|--tag)
    shift
    NP_INSTANCE_TAG_NAME=$1
    ;;  
--)
    shift
    break
    exit 0
    ;;  
esac
shift
done






# Change these four parameters as needed for your own environment
STR_ID=$RANDOM


AKS_PERS_STORAGE_ACCOUNT_NAME=stracc$STR_ID
AKS_PERS_RESOURCE_GROUP=rg-str-acc-$STR_ID
AKS_PERS_LOCATION=eastus
AKS_PERS_SHARE_NAME=aks-share-stracc$STR_ID



# Create a resource group
az group create \
  --name $AKS_PERS_RESOURCE_GROUP \
  --location $AKS_PERS_LOCATION

# Create a storage account
az storage account create \
  --name $AKS_PERS_STORAGE_ACCOUNT_NAME \
  --resource-group $AKS_PERS_RESOURCE_GROUP \
  --location $AKS_PERS_LOCATION \
  --sku Standard_LRS

# Export the connection string as an environment variable, this is used when creating the Azure file share
export AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
  -n $AKS_PERS_STORAGE_ACCOUNT_NAME \
  -g $AKS_PERS_RESOURCE_GROUP \
  -o tsv)

# Create the file share
az storage share create \
  -n $AKS_PERS_SHARE_NAME \
  --connection-string $AZURE_STORAGE_CONNECTION_STRING

# Get storage account key
STORAGE_KEY=$(az storage account keys list \
  --resource-group $AKS_PERS_RESOURCE_GROUP \
  --account-name $AKS_PERS_STORAGE_ACCOUNT_NAME \
  --query "[0].value" -o tsv)

# Echo storage account name and key
#echo Storage account name: $AKS_PERS_STORAGE_ACCOUNT_NAME
#echo Storage account key: $STORAGE_KEY


kubectl create secret generic azure-secret --from-literal=azurestorageaccountname=$AKS_PERS_STORAGE_ACCOUNT_NAME --from-literal=azurestorageaccountkey=$STORAGE_KEY






## Mount file share as an inline volume

rm -rf azure-files-pod.yaml

cat <<EOF > azure-files-pod.yaml

apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - image: mcr.microsoft.com/oss/nginx/nginx:1.15.5-alpine
    name: mypod
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
    csi:
      driver: file.csi.azure.com
      volumeAttributes:
        secretName: azure-secret  # required
        shareName: $AKS_PERS_SHARE_NAME  # required
        mountOptions: "dir_mode=0777,file_mode=0777,cache=strict,actimeo=30"  # optional
EOF

kubectl apply -f azure-files-pod.yaml




# Mount file share as a persistent volume

#apiVersion: v1
#kind: PersistentVolume
#metadata:
#  name: azurefile
#spec:
#  capacity:
#    storage: 5Gi
#  accessModes:
#    - ReadWriteMany
#  persistentVolumeReclaimPolicy: Retain
#  storageClassName: azurefile-csi
#  csi:
#    driver: file.csi.azure.com
#    readOnly: false
#    volumeHandle: unique-volumeid  # make sure this volumeid is unique in the cluster
#    volumeAttributes:
#      resourceGroup: EXISTING_RESOURCE_GROUP_NAME  # optional, only set this when storage account is not in the same resource group as agent node
#      shareName: aksshare
#    nodeStageSecretRef:
#      name: azure-secret
#      namespace: default
#  mountOptions:
#    - dir_mode=0777
#    - file_mode=0777
#    - uid=0
#    - gid=0
#    - mfsymlinks
#    - cache=strict
#    - nosharesock
#    - nobrl
#
#
#
#apiVersion: v1
#kind: PersistentVolumeClaim
#metadata:
#  name: azurefile
#spec:
#  accessModes:
#    - ReadWriteMany
#  storageClassName: azurefile-csi
#  volumeName: azurefile
#  resources:
#    requests:
#      storage: 5Gi
#
#
#kubectl apply -f azurefile-mount-options-pv.yaml
#kubectl apply -f azurefile-mount-options-pvc.yaml
#
#
