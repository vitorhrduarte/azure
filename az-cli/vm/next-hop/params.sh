## Running Options
CREATE_SRV="1"
CREATE_NVA="1"
VNET_PREFIX="10.6"


## Core Networking
VM_VNET_RG="rg-aks-24"
VM_VNET_NAME="vnet-aks-24"
VM_VNET_LOCATION="westeurope"
VM_VNET_CIDR=$VNET_PREFIX".0.0/16"

## VM Specific Networking
VM_SNET_NAME="snet-nva"
VM_SNET_CIDR=$VNET_PREFIX".100.0/28"
VM_PRIV_IP=$VNET_PREFIX".100.4/32"

## Local ISP PIP
VM_MY_ISP_IP=$(curl -s -4 ifconfig.io)

## Public IP Name
VM_PUBLIC_IP_NAME="nvasrvpip"
VM_DEFAULT_IP_CONFIG="ipconfig1"

## VM SSH Client
VM_RG_LOCATION=$AKS_MAIN_VNET_LOCATION
VM_AUTH_TYPE="ssh"
VM_NAME="nva-srv"
VM_INTERNAL_NAME="nva-srv"
VM_IMAGE_PROVIDER="Canonical"
VM_IMAGE_OFFER="0001-com-ubuntu-server-focal"
VM_IMAGE_SKU="20_04-lts-gen2"
VM_IMAGE_VERSION="latest"
VM_IMAGE="$VM_IMAGE_PROVIDER:$VM_IMAGE_OFFER:$VM_IMAGE_SKU:$VM_IMAGE_VERSION"
VM_SIZE="Standard_D2s_v3"
VM_STORAGE_SKU="Standard_LRS"
VM_OS_DISK_SIZE="40"
VM_OS_DISK_NAME="$VM_NAME""_disk_01"
VM_NSG_NAME="$VM_NAME""_nsg"
VM_NIC_NAME="$VM_NAME""nic01"
VM_TAGS="purpose=nva-server"

