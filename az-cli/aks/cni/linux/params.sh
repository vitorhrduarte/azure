## Frequent AKS Var's to change
AKS_NAME="calico"
AKS_RG_LOCATION="westeurope"
AKS_VERSION="1.22.6"
AKS_VNET_2_OCTETS="10.4"   # Define the fisrt 2 octets for Vnet
AKS_ZONES="1 2 3"          # Define AKS Zones
AKS_2ND_NP_ZONES="1 2 3"       # Defines NP Zones

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
AKS_HAS_NETWORK_POLICY="1"    # 1 = AKS has Azure Net Pol enabled
AKS_HAS_2ND_NODEPOOL="1"      # 1 = AKS has second npool
AKS_HAS_JUMP_SERVER="0"       # 1 = Deploy Linux Jump Server


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


# OS SKU
OS_SKU="Ubuntu"   # CBLMariner, Ubuntu, Windows2019, Windows2022

## AKS Networking
AKS_CNI_PLUGIN="azure"
AKS_VNET="vnet-"$AKS_CLUSTER_NAME
AKS_SNET="snet-"$AKS_CLUSTER_NAME
AKS_NET_NPOLICY="calico"   # calico or azure


## My ISP PIP
MY_HOME_PUBLIC_IP=$(curl -s -4 ifconfig.io)


## VM Settings
JS_VM_PUBLIC_IP_NAME="sshclientpublicip"
JS_VM_DEFAULT_IP_CONFIG="ipconfig1"
JS_VM_SUBNET_NAME="snet-ljs"
JS_VM_SNET_CIDR="$AKS_VNET_2_OCTETS.6.0/28"
JS_VM_PRIV_IP="$AKS_VNET_2_OCTETS.6.4/32"
JS_RG_LOCATION=$AKS_RG_LOCATION
JS_AUTH_TYPE="ssh"
JS_VM_NAME="sshclient-"$AKS_NAME
JS_VM_INTERNAL_NAME="sshclient-"$AKS_NAME
JS_IMAGE_PROVIDER="Canonical"
JS_IMAGE_OFFER="UbuntuServer"
JS_IMAGE_SKU="18.04-LTS"
JS_IMAGE_VERSION="latest"
JS_IMAGE="$JS_IMAGE_PROVIDER:$JS_IMAGE_OFFER:$JS_IMAGE_SKU:$JS_IMAGE_VERSION"
JS_PUBLIC_IP="" 
JS_VNET_NAME=$AKS_VNET
JS_VM_SIZE="Standard_D2s_v3"
JS_VM_STORAGE_SKU="Standard_LRS"
JS_VM_OS_DISK_SIZE="40"
JS_VM_OS_DISK_NAME="$JS_VM_NAME""_disk_01"
JS_VM_NSG_NAME="$JS_VM_NAME""_nsg"
JS_VM_NIC_NAME="$JS_VM_NAME""nic01"
JS_TAGS="env=kubernetes"

