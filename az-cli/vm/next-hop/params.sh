## Running Options
NVA_SETUP=0         # This should be 1 if and only if the machine have access to the NVA
NVA_CREATION=1      # This should be 1 by default. 
                    # To have 1 in setup and 1 in creation then the running machine need to ahve access to the NVA

VNET_PREFIX="10.2"                                                  # Define the Vnet Prefix
AKS_CLUSTER_NAME="aks-udr"                                          # Define the AKS Cluster Name (it will be deployed with other way)
VNET_ROUTE_TABLE_NAME="main-rt-"$AKS_CLUSTER_NAME                   # Define main Route Table
VNET_ROUTE_TABLE_ROUTE_NAME="main-route-"$AKS_CLUSTER_NAME          # Define main Route Table Route name
VNET_NVA_IP=$VNET_PREFIX".0.4"                                      # Define NVA (Linux machine in this case) IP i Vnet Of the AKS Cluster


## Core Networking
VM_VNET_RG="rg-"$AKS_CLUSTER_NAME
VM_VNET_NAME="vnet-"$AKS_CLUSTER_NAME
VM_VNET_LOCATION="westeurope"
VM_VNET_CIDR=$VNET_PREFIX".0.0/16"


## VM Specific Networking
VM_SNET_NAME="snet-nva"
VM_SNET_CIDR=$VNET_PREFIX".100.0/28"
VM_PRIV_IP=$VNET_PREFIX".100.4/32"
AKS_SNET_NAME="snet-"$AKS_CLUSTER_NAME
AKS_SNET_CIDR=$VNET_PREFIX".0.0/23"
AKS_SNET_GTW_IP=$VNET_PREFIX".0.1"     	# This IP depends on the previous definition SO BE WARE of IT
					# Should be the fisrt available IP, example:
					# CIDR 10.2.0.0/23, GTW IP= 10.2.0.1

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
VM_NIC_NAME="$VM_NAME""nic01"           # Primary NIC
VM_NIC_NAME_2="$VM_NAME""nic02"         # Second NIC with IP Forwarding (with IP in the subnet of AKS)
VM_TAGS="purpose=nva-server"

