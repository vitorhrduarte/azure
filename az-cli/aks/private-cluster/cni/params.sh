## Frequent AKS Var's to change
AKS_NAME="pall"                 # Define AKS name/purpose 
AKS_RG_LOCATION="westeurope"  # Define AKS location
AKS_VERSION="1.20.13"         # Define AKS Version
AKS_VNET_2_OCTETS="10.4"      # Define the fisrt 2 Octets for AKS Vnet
LJ_VNET_PREFIX="10.200"       # Define the Jump Server Vnet Prefix, fisrt 2 Octets

## AKS Vnet Settings
AKS_VNET_CIDR="$AKS_VNET_2_OCTETS.0.0/16"
AKS_SNET_CIDR="$AKS_VNET_2_OCTETS.0.0/23"
AKS_CLUSTER_SRV_CIDR="$AKS_VNET_2_OCTETS.2.0/24"
AKS_CLUSTER_DNS="$AKS_VNET_2_OCTETS.2.10"
AKS_CLUSTER_DOCKER_BRIDGE="172.17.0.1/16"


## AKS Add-ons and other options
AKS_HAS_AZURE_MONITOR="0"     # 1 = AKS has Az Mon enabled
AKS_HAS_AUTO_SCALER="0"       # 1 = AKS has Auto Scaler enabled
AKS_HAS_MANAGED_IDENTITY="1"  # 1 = AKS has Managed Identity enabled
AKS_HAS_NETWORK_POLICY="0"    # 1 = AKS has Azure Net Pol enabled
AKS_HAS_2ND_NODEPOOL="0"      # 1 = AKS has second npool
AKS_CREATE_JUMP_SERVER="0"    # 1 = If we need to create a JS from Other Vnet 
AKS_HAS_JUMP_SERVER="1"       # 1 = If we already have a Jump Server from Other Vnet, with Peered Vnet 

#########################################################################
## If AKS_HAS_JUMP_SERVER="1" then we need to define the setting below
#########################################################################
EXISTING_JUMP_SERVER_VNET_NAME="vnet-vm-jpsrv"


## AKS Specifics
AKS_RG_NAME="rg-aks-"$AKS_NAME
AKS_CLUSTER_NAME="aks-"$AKS_NAME
AKS_SYS_NP_NODE_SIZE="Standard_D4s_v3"
AKS_USR_NP_NODE_SIZE="Standard_D4s_v3"
AKS_SYS_NP_NODE_COUNT="1"
AKS_USR_NP_NODE_COUNT="2"
AKS_SYS_NP_NODE_DISK_SIZE="90"
AKS_USR_NP_NODE_DISK_SIZE="100"
AKS_NP_VM_TYPE="VirtualMachineScaleSets"
AKS_MAX_PODS_PER_NODE="30"


## AKS Networking
AKS_CNI_PLUGIN="azure"              # We can change to Kubenet
AKS_VNET="vnet-"$AKS_NAME
AKS_SNET="snet-"$AKS_NAME
AKS_NET_NPOLICY="Azure"             # We can change to Calico


## My ISP PIP
MY_HOME_PUBLIC_IP=$(curl -s -4 ifconfig.io)


## VM Settings
LJ_LOCATION="$AKS_RG_LOCATION"
LJ_VNET="vnet-users"
LJ_RG="rg-vm-$AKS_CLUSTER_NAME"
LJ_VNET_CIDR="$LJ_VNET_PREFIX.0.0/24"
LJ_SNET="subnet-users"
LJ_SNET_CIDR="$LJ_VNET_PREFIX.0.0/28"
LJ_PRIV_IP="$LJ_VNET_PREFIX.0.4/32"
LJ_NAME="lclt-"$AKS_NAME
LJ_INTERNAL_NAME="lclt-"$AKS_NAME
LJ_IMAGE_PROVIDER="Canonical"
LJ_IMAGE_OFFER="UbuntuServer"
LJ_IMAGE_SKU="18.04-LTS"
LJ_IMAGE_VERSION="latest"
LJ_IMAGE="$LJ_IMAGE_PROVIDER:$LJ_IMAGE_OFFER:$LJ_IMAGE_SKU:$LJ_IMAGE_VERSION"
LJ_SIZE="Standard_D2s_v3"
LJ_OS_DISK_SIZE="40"
LJ_PIP="$LJ_NAME-pip"
LJ_DEFAULT_IP_CONFIG="ipconfig1"
LJ_STORAGE_SKU="Standard_LRS"
LJ_AUTH_TYPE="ssh"
LJ_NSG_NAME="$LJ_NAME""_nsg"
LJ_NIC_NAME="$LJ_NAME""nic01"
LJ_OS_DISK_NAME="$LJ_NAME""_disk_01"
LJ_TAGS="env=jump-server"
