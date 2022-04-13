## Running Options
JUST_BIND="0"              # 1 - If we just want to deploy Bind server
ALL="1"                    # 1 - If we want to deploy all, VM + Bind
AKS_VNET_PREFIX="10.3"     # Having in mind Vnet Peering, we need to make sure no Vnet overlaps


## Core Networking
MAIN_VNET_RG="rg-aks-dns"
MAIN_VNET_NAME="vnet-aks-dns"
MAIN_VNET_LOCATION="westeurope"

## AKS SubNet details
AKS_SUBNET_CIDR="$AKS_VNET_PREFIX.0.0/23"

## Bind9 Forwarders
VM_BIND_FORWARDERS_01="1.1.1.1"
VM_BIND_FORWARDERS_02="8.8.8.8"

## VM Specific Networking
VM_DNS_SUBNET_NAME="dns-server"
VM_DNS_SNET_CIDR="$AKS_VNET_PREFIX.10.0/28"
VM_DNS_PRIV_IP="$AKS_VNET_PREFIX.10.4/32"

## Local ISP PIP
VM_MY_ISP_IP=$(curl -s -4 ifconfig.io)

## Public IP Name
VM_DNS_PUBLIC_IP_NAME="dnssrvpip"
VM_DNS_DEFAULT_IP_CONFIG="ipconfig1"

## VM SSH Client
VM_RG_LOCATION=$MAIN_VNET_LOCATION
VM_AUTH_TYPE="ssh"
VM_NAME="dns-srv"
VM_INTERNAL_NAME="dns-srv"
VM_IMAGE_PROVIDER="Canonical"
VM_IMAGE_OFFER="UbuntuServer"
VM_IMAGE_SKU="18.04-LTS"
VM_IMAGE_VERSION="latest"
VM_IMAGE="$VM_IMAGE_PROVIDER:$VM_IMAGE_OFFER:$VM_IMAGE_SKU:$VM_IMAGE_VERSION"
VM_PUBLIC_IP="" 
VM_SIZE="Standard_D2s_v3"
VM_STORAGE_SKU="Standard_LRS"
VM_OS_DISK_SIZE="40"
VM_OS_DISK_NAME="$VM_NAME""_disk_01"
VM_NSG_NAME="$VM_NAME""_nsg"
VM_NIC_NAME="$VM_NAME""nic01"
VM_TAGS="purpose=dns-server"

