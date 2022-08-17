## Frequent AKS Var's to change
AKS_NAME="udr"
AKS_RG_LOCATION="westeurope"
AKS_VERSION="1.24.0"
AKS_ZONES="1 2 3"             # Define AKS Zones
AKS_2ND_NP_ZONES="1"          # Defines NP Zones
AKS_VNET_2_OCTETS="10.2"      # Vnet Fisrt 2 Octets


## AKS Vnet Settings
AKS_CLUSTER_SRV_CIDR="$AKS_VNET_2_OCTETS.2.0/24"
AKS_CLUSTER_DNS="$AKS_VNET_2_OCTETS.2.10"
AKS_CLUSTER_DOCKER_BRIDGE="172.17.0.1/16"


## AKS Add-ons and other options
AKS_HAS_AZURE_MONITOR="0"     # 1 = AKS has Az Mon enabled
AKS_HAS_AUTO_SCALER="0"       # 1 = AKS has Auto Scaler enabled
AKS_HAS_MANAGED_IDENTITY="1"  # 1 = AKS has Managed Identity enabled
AKS_HAS_NETWORK_POLICY="0"    # 1 = AKS has Azure Net Pol enabled
AKS_HAS_2ND_NODEPOOL="0"      # 1 = AKS has second npool
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


## AKS Networking
AKS_CNI_PLUGIN="azure"
AKS_VNET="vnet-"$AKS_CLUSTER_NAME
AKS_SNET="snet-"$AKS_CLUSTER_NAME
AKS_NET_NPOLICY="Azure"   # Calico


