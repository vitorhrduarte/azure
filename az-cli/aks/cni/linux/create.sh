##!/usr/bin/env bash
set -e
. ./params.sh


## Create Resource Group for Cluster VNet
echo "Create RG for Cluster Vnet"
az group create \
  --name $AKS_RG_NAME \
  --location $AKS_RG_LOCATION \
  --tags env=$AKS_CLUSTER_NAME \
  --debug

## Create  VNet and Subnet
echo "Create Vnet and Subnet for AKS Cluster"
az network vnet create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_VNET \
  --address-prefix $AKS_VNET_CIDR \
  --subnet-name $AKS_SNET \
  --subnet-prefix $AKS_SNET_CIDR \
  --debug

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
  echo "Creating AKS with Monitor Enabled, AutoScaler, Managed Idenity and Network Policy = $AKS_NET_NPOLICY"
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
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
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
  --yes \
  --os-sku $OS_SKU \
  --debug 
elif [[ $AKS_HAS_AZURE_MONITOR -eq 1 && $AKS_HAS_AUTO_SCALER -eq 1 && $AKS_HAS_MANAGED_IDENTITY -eq 1 && $AKS_HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Monitor Enabled, AutoScaler, Managed Identity and Net Pol $AKS_NET_NPOLICY"
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
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
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
  --yes \
  --os-sku $OS_SKU \
  --debug
elif [[ $AKS_HAS_AZURE_MONITOR -eq 1 && $AKS_HAS_AUTO_SCALER -eq 0 && $AKS_HAS_MANAGED_IDENTITY -eq 1 && $AKS_HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Monitor Enabled, Managed Idenity and Net Pol $AKS_NET_NPOLICY"
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
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons monitoring \
  --enable-managed-identity \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --yes \
  --os-sku $OS_SKU \
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
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
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
  --os-sku $OS_SKU \
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
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons monitoring \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --os-sku $OS_SKU \
  --debug
elif [[ $AKS_HAS_AZURE_MONITOR -eq 0 && $AKS_HAS_AUTO_SCALER -eq 0 && $AKS_HAS_MANAGED_IDENTITY -eq 1 && $AKS_HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Managed Identity and Net Pol $AKS_NET_NPOLICY"
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
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-managed-identity \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --yes \
  --os-sku $OS_SKU \
  --debug
elif [[ $AKS_HAS_AZURE_MONITOR -eq 0 && $AKS_HAS_AUTO_SCALER -eq 0 && $AKS_HAS_MANAGED_IDENTITY -eq 1 && $AKS_HAS_NETWORK_POLICY -eq 1 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Managed Identityi and Network Policy = $AKS_NET_NPOLICY" 
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
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-managed-identity \
  --network-policy $AKS_NET_NPOLICY \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --yes \
  --os-sku $OS_SKU \
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
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons monitoring \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --os-sku $OS_SKU \
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
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3 \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --yes \
  --os-sku $OS_SKU \
  --debug
elif [[ $AKS_HAS_AZURE_MONITOR -eq 0 && $AKS_HAS_AUTO_SCALER -eq 1 && $AKS_HAS_MANAGED_IDENTITY -eq 1 && $AKS_HAS_NETWORK_POLICY -eq 1 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with AutoScaler MSI and Network Policy $AKS_NET_NPOLICY"
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
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
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
  --yes \
  --os-sku $OS_SKU \
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
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --nodepool-name sysnp \
  --nodepool-tags "env=sysnp" \
  --max-pods $AKS_MAX_PODS_PER_NODE \
  --zones $AKS_ZONES \
  --os-sku $OS_SKU \
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
    --os-sku $OS_SKU \
    --debug
  fi
fi


if [[ "$AKS_HAS_JUMP_SERVER" == "1" ]] 
then

  ## VM Jump Client subnet Creation
  echo "Create VM Subnet"
  az network vnet subnet create \
    --resource-group $AKS_RG_NAME \
    --vnet-name $AKS_VNET \
    --name $JS_VM_SUBNET_NAME \
    --address-prefixes $JS_VM_SNET_CIDR \
    --debug
  
  
  ## VM NSG Create
  echo "Create NSG"
  az network nsg create \
    --resource-group $AKS_RG_NAME \
    --name $JS_VM_NSG_NAME \
    --debug
  
  ## Public IP Create
  echo "Create Public IP"
  az network public-ip create \
    --name $JS_VM_PUBLIC_IP_NAME \
    --resource-group $AKS_RG_NAME \
    --debug
  
  
  ## VM Nic Create
  echo "Create VM Nic"
  az network nic create \
    --resource-group $AKS_RG_NAME \
    --vnet-name $JS_VNET_NAME \
    --subnet $JS_VM_SUBNET_NAME \
    --name $JS_VM_NIC_NAME \
    --network-security-group $JS_VM_NSG_NAME \
    --debug 
  
  ## Attache Public IP to VM NIC
  echo "Attach Public IP to VM NIC"
  az network nic ip-config update \
    --name $JS_VM_DEFAULT_IP_CONFIG \
    --nic-name $JS_VM_NIC_NAME \
    --resource-group $AKS_RG_NAME \
    --public-ip-address $JS_VM_PUBLIC_IP_NAME \
    --debug
  
  ## Update NSG in VM Subnet
  echo "Update NSG in VM Subnet"
  az network vnet subnet update \
    --resource-group $AKS_RG_NAME \
    --name $JS_VM_SUBNET_NAME \
    --vnet-name $AKS_VNET \
    --network-security-group $JS_VM_NSG_NAME \
    --debug

  ## Create VM
  echo "Create VM"
  az vm create \
    --resource-group $AKS_RG_NAME \
    --authentication-type $JS_AUTH_TYPE \
    --name $JS_VM_NAME \
    --computer-name $JS_VM_INTERNAL_NAME \
    --image $JS_IMAGE \
    --size $JS_VM_SIZE \
    --admin-username $GENERIC_ADMIN_USERNAME \
    --ssh-key-values $ADMIN_USERNAME_SSH_KEYS_PUB \
    --storage-sku $JS_VM_STORAGE_SKU \
    --os-disk-size-gb $JS_VM_OS_DISK_SIZE \
    --os-disk-name $JS_VM_OS_DISK_NAME \
    --nics $JS_VM_NIC_NAME \
    --tags $JS_TAGS \
    --debug
  
  echo "Sleeping 45s - Allow time for Public IP"
  sleep 45
  
  ## Output Public IP of VM
  echo "Getting Public IP of VM"
  VM_PUBLIC_IP=$(az network public-ip list \
    --resource-group $AKS_RG_NAME \
    --output json | jq -r ".[] | select ( .name == \"$JS_VM_PUBLIC_IP_NAME\" ) | [ .ipAddress ] | @tsv")
  echo "Public IP of VM is:" 
  echo $VM_PUBLIC_IP

  ## Allow SSH from my Home
  echo "Update VM NSG to allow SSH"
  az network nsg rule create \
    --nsg-name $JS_VM_NSG_NAME \
    --resource-group $AKS_RG_NAME \
    --name ssh_allow \
    --priority 100 \
    --source-address-prefixes $MY_HOME_PUBLIC_IP \
    --source-port-ranges '*' \
    --destination-address-prefixes $JS_VM_PRIV_IP \
    --destination-port-ranges 22 \
    --access Allow \
    --protocol Tcp \
    --description "Allow from MY ISP IP"
  
  ## Input Key Fingerprint
  echo "Input Key Fingerprint" 
  FINGER_PRINT_CHECK=$(ssh-keygen -F $VM_PUBLIC_IP >/dev/null | ssh-keyscan -H $VM_PUBLIC_IP | wc -l)
  
  while [[ "$FINGER_PRINT_CHECK" = "0" ]]
  do
    echo "not good to go: $FINGER_PRINT_CHECK"
    echo "Sleeping for 5s..."
    sleep 5
    FINGER_PRINT_CHECK=$(ssh-keygen -F $VM_PUBLIC_IP >/dev/null | ssh-keyscan -H $VM_PUBLIC_IP | wc -l)
  done
  
  echo "Go to go with Input Key Fingerprint"
  ssh-keygen -F $VM_PUBLIC_IP >/dev/null | ssh-keyscan -H $VM_PUBLIC_IP >> ~/.ssh/known_hosts
  
  ## Copy to VM AKS SSH Priv Key
  echo "Copy to VM priv Key of AKS Cluster"
  scp  -o 'StrictHostKeyChecking no' -i $SSH_PRIV_KEY $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP:/home/$GENERIC_ADMIN_USERNAME/id_rsa
  
  ## Set Correct Permissions on Priv Key
  echo "Set good Permissions on AKS Priv Key"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP "chmod 700 /home/$GENERIC_ADMIN_USERNAME/id_rsa"
  
  ## Install and update software
  echo "Updating VM and Stuff"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP "sudo apt update && sudo apt upgrade -y"
  
  ## VM Install software
  echo "VM Install software"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP sudo apt install tcpdump wget snap dnsutils -y

  ## Add Az Cli
  echo "Add Az Cli"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
  
  ## Install Kubectl
  echo "Install Kubectl"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP sudo snap install kubectl --classic
  
  ## Install JQ
  echo "Install JQ"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP sudo snap install jq
  
  ## Add Kubectl completion
  echo "Add Kubectl completion"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP "source <(kubectl completion bash)"

  ## Add Win password
  echo "Add Win password"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP "touch ~/win-pass.txt && echo "$WINDOWS_AKS_ADMIN_PASSWORD" > ~/win-pass.txt"
  
  ## Create the SSH into Node Helper file
  echo "Process SSH into Node into SSH VM"
  AKS_1ST_NODE_IP=$(kubectl get nodes -o=wide | awk 'FNR == 2 {print $6}')
  AKS_STRING_TO_DO_SSH='ssh -o ServerAliveInterval=180 -o ServerAliveCountMax=2 -i id_rsa'
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP echo "$AKS_STRING_TO_DO_SSH $GENERIC_ADMIN_USERNAME@$AKS_1ST_NODE_IP >> gtno.sh"

  echo "Public IP of the VM"
  echo $VM_PUBLIC_IP

fi

## Get Credentials
echo "Getting Cluster Credentials"
az aks get-credentials --resource-group $AKS_RG_NAME --name $AKS_CLUSTER_NAME --overwrite-existing

