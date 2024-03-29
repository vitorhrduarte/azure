## Running Options
CREATE_MAIL_SRV="1"   # 1 - If we want just to deploy the VM
CREATE_POSTFIX="1"    # 1 - If we want to deploy Bind setup, assuming existing VM
VNET_PREFIX="10.3"    # Define Vnet Prefix CIDR


## Core Networking
AKS_MAIN_VNET_RG="rg-aks-dns"         # Vnet RG Name
AKS_MAIN_VNET_NAME="vnet-aks-dns"     # Vnet Name
AKS_MAIN_VNET_LOCATION="westeurope"   # Vnet/RG Location
AKS_MAIN_VNET_CIDR="$VNET_PREFIX.0.0/16"      # Vnet CIDR
AKS_SUBNET_CIDR="$VNET_PREFIX.0.0/23"         # Vnet Snet CIDR

## VM Specific Networking
VM_MAIL_SUBNET_NAME="mail-server"
VM_MAIL_SNET_CIDR="$VNET_PREFIX.100.0/28"
VM_MAIL_PRIV_IP="$VNET_PREFIX.100.4/32"

## Local ISP PIP
VM_MY_ISP_IP=$(curl -s -4 ifconfig.io)

## Public IP Name
VM_MAIL_PUBLIC_IP_NAME="mailsrvpip"
VM_MAIL_DEFAULT_IP_CONFIG="ipconfig1"

## VM SSH Client
VM_MAIL_RG_LOCATION=$AKS_MAIN_VNET_LOCATION
VM_MAIL_AUTH_TYPE="ssh"
VM_MAIL_NAME="mail-srv"
VM_MAIL_INTERNAL_NAME="mail-srv"
VM_MAIL_IMAGE_PROVIDER="Canonical"
VM_MAIL_IMAGE_OFFER="0001-com-ubuntu-server-focal"
VM_MAIL_IMAGE_SKU="20_04-lts-gen2"
VM_MAIL_IMAGE_VERSION="latest"
VM_MAIL_IMAGE="$VM_MAIL_IMAGE_PROVIDER:$VM_MAIL_IMAGE_OFFER:$VM_MAIL_IMAGE_SKU:$VM_MAIL_IMAGE_VERSION"
VM_MAIL_PUBLIC_IP="" 
VM_MAIL_SIZE="Standard_D2s_v3"
VM_MAIL_STORAGE_SKU="Standard_LRS"
VM_MAIL_OS_DISK_SIZE="40"
VM_MAIL_OS_DISK_NAME="$VM_MAIL_NAME""_disk_01"
VM_MAIL_NSG_NAME="$VM_MAIL_NAME""_nsg"
VM_MAIL_NIC_NAME="$VM_MAIL_NAME""nic01"
VM_MAIL_TAGS="purpose=mail-server"

