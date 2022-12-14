#!/bin/bash


AKS_RG_NAME="rg-aks-ckad"
AKS_CLUSTER_NAME="aks-ckad"
AKS_AZ_DISK_NAME="ckadshare"
AKS_AZ_DISK_SIZE_IN_GB="20"




## Get Infra RG for AKS
echo "Get Infra RG for AKS"
AKS_INFRA_RG_NAME=$(az aks show \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --query nodeResourceGroup -o tsv)

## Create Azure Disk
echo "Create Azure Disk"
az disk create \
  --resource-group $AKS_INFRA_RG_NAME \
  --name $AKS_AZ_DISK_NAME \
  --size-gb $AKS_AZ_DISK_SIZE_IN_GB \
  --query id \
  --output tsv

## Get Azure Disk URI
echo "Get Azure Disk URI"
AKS_AZ_DISK_URI=$(az disk list \
  --resource-group $AKS_INFRA_RG_NAME \
  --output json | jq -r ".[].id")

## Clean some files
echo "Clean some files"
rm -rf azure-disk-pv-name.yaml
rm -rf azure-disk-pvc-name.yaml
rm -rf pod.yaml

## Create PV
echo "Create PV"
cat <<EOF > azure-disk-pv-name.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-azuredisk
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: managed-csi
  csi:
    driver: disk.csi.azure.com
    readOnly: false
    volumeHandle: $AKS_AZ_DISK_URI
    volumeAttributes:
      fsType: ext4
EOF

kubectl apply -f azure-disk-pv-name.yaml


## Create PVC
echo "Create PVC"
cat <<EOF > azure-disk-pvc-name.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-azuredisk
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  volumeName: pv-azuredisk
  storageClassName: managed-csi
EOF
 
kubectl apply -f azure-disk-pvc-name.yaml


## Create Pod
echo "Create Pod"
cat <<EOF > pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  nodeSelector:
    kubernetes.io/os: linux
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
      persistentVolumeClaim:
        claimName: pvc-azuredisk
EOF

kubectl apply -f pod.yaml
