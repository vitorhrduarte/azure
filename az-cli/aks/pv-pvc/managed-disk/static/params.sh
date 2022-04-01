## AKS
AKS_CLUSTER_NAME="aks-ckad"
AKS_RG_NAME="rg-"$AKS_CLUSTER_NAME
AKS_STATIC_DISK_NAME="sdisk00"
AKS_STATIC_DISK_SIZE_IN_GB="20"

## POD
POD_NAME="mypod"
POD_IMAGE="mcr.microsoft.com/oss/nginx/nginx:1.15.5-alpine"
