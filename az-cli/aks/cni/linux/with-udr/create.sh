##!/usr/bin/env bash
set -e
. ./params.sh

## Get Subnet Info
echo "Getting Subnet ID"
AKS_SNET_ID=$(az network vnet subnet show \
  --resource-group $AKS_RG_NAME \
  --vnet-name $AKS_VNET \
  --name $AKS_SNET \
  --query id -o tsv)

## Create AKS Cluster
echo "Creating AKS Cluster"
if [[ $AKS_HAS_AZURE_MONITOR -eq 1 && $AKS_HAS_AUTO_SCALER -eq 1 && $AKS_HAS_MANAGED_IDENTITY -eq 1 && $AKS_HAS_NETWORK_POLICY -eq 1 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Monitor Enabled, AutoScaler, Managed Idenity and Network Policy = Azure"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --node-count $AKS_SYS_NP_NODE_COUNT \
  --node-vm-size $AKS_SYS_NP_NODE_SIZE \
  --location $AKS_RG_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_NP_VM_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons monitoring \
  --network-policy $AKS_NET_NPOLICY \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3 \
  --enable-managed-identity \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --outbound-type userDefinedRouting \
  --yes \
  --debug 
elif [[ $AKS_HAS_AZURE_MONITOR -eq 1 && $AKS_HAS_AUTO_SCALER -eq 1 && $AKS_HAS_MANAGED_IDENTITY -eq 1 && $AKS_HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Monitor Enabled, AutoScaler, Managed Idenity"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --node-count $AKS_SYS_NP_NODE_COUNT \
  --node-vm-size $AKS_SYS_NP_NODE_SIZE \
  --location $AKS_RG_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_NP_VM_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons monitoring \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3 \
  --enable-managed-identity \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --outbound-type userDefinedRouting \
  --yes \
  --debug
elif [[ $AKS_HAS_AZURE_MONITOR -eq 1 && $AKS_HAS_AUTO_SCALER -eq 0 && $AKS_HAS_MANAGED_IDENTITY -eq 1 && $AKS_HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Monitor Enabled, Managed Idenity"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --node-count $AKS_SYS_NP_NODE_COUNT \
  --node-vm-size $AKS_SYS_NP_NODE_SIZE \
  --location $AKS_RG_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_NP_VM_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons monitoring \
  --enable-managed-identity \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --outbound-type userDefinedRouting \
  --yes \
  --debug  
elif [[ $AKS_HAS_AZURE_MONITOR -eq 1 && $AKS_HAS_AUTO_SCALER -eq 1 && $AKS_HAS_MANAGED_IDENTITY -eq 0 && $AKS_HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Monitor Enabled, AutoScaler"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --service-principal $SP \
  --client-secret $SPPASS \
  --node-count $AKS_SYS_NP_NODE_COUNT \
  --node-vm-size $AKS_SYS_NP_NODE_SIZE \
  --location $AKS_RG_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_NP_VM_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons monitoring \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3 \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --outbound-type userDefinedRouting \
  --yes \
  --debug
elif [[ $AKS_HAS_AZURE_MONITOR -eq 1 && $AKS_HAS_AUTO_SCALER -eq 0 && $AKS_HAS_MANAGED_IDENTITY -eq 0 && $AKS_HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --service-principal $SP \
  --client-secret $SPPASS \
  --node-count $AKS_SYS_NP_NODE_COUNT \
  --node-vm-size $AKS_SYS_NP_NODE_SIZE \
  --location $AKS_RG_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_NP_VM_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons monitoring \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --outbound-type userDefinedRouting \
  --yes \
  --debug
elif [[ $AKS_HAS_AZURE_MONITOR -eq 0 && $AKS_HAS_AUTO_SCALER -eq 0 && $AKS_HAS_MANAGED_IDENTITY -eq 1 && $AKS_HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Managed Identity"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --node-count $AKS_SYS_NP_NODE_COUNT \
  --node-vm-size $AKS_SYS_NP_NODE_SIZE \
  --location $AKS_RG_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_NP_VM_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-managed-identity \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --outbound-type userDefinedRouting \
  --yes \
  --debug
elif [[ $AKS_HAS_AZURE_MONITOR -eq 0 && $AKS_HAS_AUTO_SCALER -eq 0 && $AKS_HAS_MANAGED_IDENTITY -eq 1 && $AKS_HAS_NETWORK_POLICY -eq 1 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Managed Identityi and Network Policy = Azure" 
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --node-count $AKS_SYS_NP_NODE_COUNT \
  --node-vm-size $AKS_SYS_NP_NODE_SIZE \
  --location $AKS_RG_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_NP_VM_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-managed-identity \
  --network-policy $AKS_NET_NPOLICY \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --outbound-type userDefinedRouting \
  --yes \
  --debug
elif [[ $AKS_HAS_AZURE_MONITOR -eq 1 && $AKS_HAS_AUTO_SCALER -eq 0 && $AKS_HAS_MANAGED_IDENTITY -eq 0 && $AKS_HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Monitor" 
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --service-principal $SP \
  --client-secret $SPPASS \
  --node-count $AKS_SYS_NP_NODE_COUNT \
  --node-vm-size $AKS_SYS_NP_NODE_SIZE \
  --location $AKS_RG_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_NP_VM_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons monitoring \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --outbound-type userDefinedRouting \
  --debug
elif [[ $AKS_HAS_AZURE_MONITOR -eq 0 && $AKS_HAS_AUTO_SCALER -eq 1 && $AKS_HAS_MANAGED_IDENTITY -eq 0 && $AKS_HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with AutoScaler"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --service-principal $SP \
  --client-secret $SPPASS \
  --node-count $AKS_SYS_NP_NODE_COUNT \
  --node-vm-size $AKS_SYS_NP_NODE_SIZE \
  --location $AKS_RG_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_NP_VM_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3 \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --outbound-type userDefinedRouting \
  --yes \
  --debug
elif [[ $AKS_HAS_AZURE_MONITOR -eq 0 && $AKS_HAS_AUTO_SCALER -eq 1 && $AKS_HAS_MANAGED_IDENTITY -eq 1 && $AKS_HAS_NETWORK_POLICY -eq 1 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with AutoScaler MSI and Network Policy"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --node-count $AKS_SYS_NP_NODE_COUNT \
  --node-vm-size $AKS_SYS_NP_NODE_SIZE \
  --location $AKS_RG_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_NP_VM_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-cluster-autoscaler \
  --enable-managed-identity \
  --network-policy $AKS_NET_NPOLICY \
  --min-count 1 \
  --max-count 3 \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --outbound-type userDefinedRouting \
  --yes \
  --debug
else
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS without Monitor"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --service-principal $SP \
  --client-secret $SPPASS \
  --node-count $AKS_SYS_NP_NODE_COUNT \
  --node-vm-size $AKS_SYS_NP_NODE_SIZE \
  --location $AKS_RG_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_NP_VM_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --outbound-type userDefinedRouting \
  --yes \
  --debug
fi

## Logic for VMASS only
if [[ "$AKS_NP_VM_TYPE" == "AvailabilitySet" ]]; then
  echo "Skip second Nodepool - VMAS dont have it"
else
  if [[ "$AKS_HAS_2ND_NODEPOOL"  == "1" ]]; then
  ## Add User nodepooll
  echo 'Add Node pool type User'
  az aks nodepool add \
    --resource-group $AKS_RG_NAME \
    --name usrnp \
    --cluster-name $AKS_CLUSTER_NAME \
    --node-osdisk-type Ephemeral \
    --node-osdisk-size $AKS_USR_NP_NODE_DISK_SIZE \
    --kubernetes-version $AKS_VERSION \
    --tags "env=userpool" \
    --mode User \
    --node-count $AKS_USR_NP_NODE_COUNT \
    --node-vm-size $AKS_USR_NP_NODE_SIZE \
    --max-pods $AKS_MAX_PODS_PER_NODE \
    --zones $AKS_2ND_NP_ZONES \
    --debug
  fi
fi


## Get Credentials
echo "Getting Cluster Credentials"
az aks get-credentials --resource-group $AKS_RG_NAME --name $AKS_CLUSTER_NAME --overwrite-existing

