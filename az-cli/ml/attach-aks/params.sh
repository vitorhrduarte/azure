## AKS
HAS_AZURE_MONITOR="0"
HAS_AUTO_SCALER="0"
HAS_MANAGED_IDENTITY="0"
HAS_NETWORK_POLICY="0"

PURPOSE="mlsp"
LOCATION="westeurope"
RG_NAME="rg-aks-"$PURPOSE
CLUSTER_NAME="aks-"$PURPOSE
NODE_SIZE="Standard_D4s_v3"
USER_NODE_SIZE="Standard_D4s_v3"
NODE_COUNT="3"
USER_NODE_COUNT="1"
NODE_DISK_SIZE="90"
USER_NODE_DISK_SIZE="100"
VMSETTYPE="VirtualMachineScaleSets"
#VMSETTYPE="AvailabilitySet"
VERSION="1.18.14"

## Networking
VNET_RG=$RG_NAME
CNI_PLUGIN="azure"
AKS_VNET="vnet-full-"$CLUSTER_NAME
AKS_VNET_RG="rg-vnet-full-"$CLUSTER_NAME
AKS_VNET_CIDR="10.0.0.0/16"
AKS_SNET="snet-full-"$PURPOSE
AKS_SNET_CIDR="10.0.0.0/22"
AKS_CLUSTER_SRV_CIDR="10.0.4.0/23"
AKS_CLUSTER_DNS="10.0.4.10"
AKS_CLUSTER_DOCKER_BRIDGE="172.17.0.1/16"
VM_SUBNET_NAME="ssh-client"
VM_SNET_CIDR="10.0.6.0/28"
VM_PRIV_IP="10.0.6.4/32"
MY_HOME_PUBLIC_IP=$(curl ifconfig.io)

## Public IP name
VM_PUBLIC_IP_NAME="sshclientpublicip"
VM_DEFAULT_IP_CONFIG="ipconfig1"

## VM SSH Client
RG_LOCATION=$LOCATION
AUTH_TYPE="ssh"
VM_NAME="sshclient-"$PURPOSE
VM_INTERNAL_NAME="sshclient-"$PURPOSE
IMAGE_PROVIDER="Canonical"
IMAGE_OFFER="UbuntuServer"
IMAGE_SKU="18.04-LTS"
IMAGE_VERSION="latest"
IMAGE="$IMAGE_PROVIDER:$IMAGE_OFFER:$IMAGE_SKU:$IMAGE_VERSION"
PUBLIC_IP="" 
VNET_NAME=$AKS_VNET
VNET_SUBNET_NAME="ssh-client"
VM_SIZE="Standard_D2s_v3"
VM_STORAGE_SKU="Standard_LRS"
VM_OS_DISK_SIZE="40"
VM_OS_DISK_NAME="$VM_NAME""_disk_01"
VM_NSG_NAME="$VM_NAME""_nsg"
VM_NIC_NAME="$VM_NAME""nic01"
TAGS="env=kubernetes"

## ML Workspace
ML_RG_NAME="rg-ml-"$PURPOSE
ML_RG_LOCATION="westeurope"
ML_WORK_SPACE_NAME="ml-aks-wkspace"

