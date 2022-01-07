## AKS
AKS_PURPOSE="plb"
AKS_LOCATION="westus"
AKS_RG_NAME="rg-aks-"$AKS_PURPOSE
AKS_CLUSTER_NAME="aks-"$AKS_PURPOSE
AKS_NODE_SIZE="Standard_D4s_v3"
AKS_NODE_COUNT="2"
AKS_NODE_DISK_SIZE="50"
AKS_VERSION="1.21.2"
AKS_CNI_PLUGIN="azure"
AKS_DOCKER_BRIDGE_ADDRESS="172.17.0.1/16"
AKS_DNS_SERVICE="10.2.0.10"
AKS_SERVICE_CIDR="10.2.0.0/24"


## Networking
AKS_VNET="vnet-aks"
AKS_VNET_RG=$AKS_RG_NAME
AKS_VNET_CIDR="10.10.0.0/16"
AKS_SNET="aks-subnet"
AKS_SNET_CIDR="10.10.0.0/23"
LJ_USERS_VNET="vnet-users"
LJ_USERS_RG="rg-aks-$AKS_PURPOSE-users"
LJ_USERS_VNET_CIDR="10.100.0.0/16"
LJ_USERS_SNET="users-subnet"
LJ_USERS_SNET_CIDR="10.100.100.0/24"

## Peering
AKS_VNET_SOURCE_RG=$AKS_VNET_RG
AKS_VNET_SOURCE=$AKS_VNET
LJ_VNET_DEST_RG=$LJ_USERS_RG
LJ_VNET_DEST=$LJ_USERS_VNET

## Jumpbox VM
LJ_VM_NAME="vm-jbox"
LJ_IMAGE_PROVIDER="Canonical"
LJ_IMAGE_OFFER="UbuntuServer"
LJ_IMAGE_SKU="18.04-LTS"
LJ_IMAGE_VERSION="latest"
LJ_IMAGE="$LJ_IMAGE_PROVIDER:$LJ_IMAGE_OFFER:$LJ_IMAGE_SKU:$LJ_IMAGE_VERSION"
LJ_VM_SIZE="Standard_D2s_v3"
LJ_VM_OSD_SIZE="32"
LJ_VM_RG=$LJ_USERS_RG
LJ_VM_VNET=$LJ_USERS_VNET
LJ_VM_SNET=$LJ_USERS_SNET
LJ_VM_SNET_CIDR="10.100.110.0/28"
LJ_VM_PUBIP="vm-jbox-pip"
LJ_VM_STORAGE_SKU="Standard_LRS"
LJ_AUTH_TYPE="ssh"
