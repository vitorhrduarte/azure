##!/usr/bin/env bash
set -e
. ./params.sh


## Create Resource Group for Cluster VNet
echo "Create RG for Cluster Vnet"
az group create \
  --name $VNET_RG \
  --location $LOCATION \
  --debug

## Create  VNet and Subnet
echo "Create Vnet and Subnet for AKS Cluster"
az network vnet create \
    -g $VNET_RG \
    -n $AKS_VNET \
    --address-prefix $AKS_VNET_CIDR \
    --subnet-name $AKS_SNET \
    --subnet-prefix $AKS_SNET_CIDR \
    --debug

## get subnet info
echo "Getting Subnet ID"
AKS_SNET_ID=$(az network vnet subnet show \
  --resource-group $VNET_RG \
  --vnet-name $AKS_VNET \
  --name $AKS_SNET \
  --query id -o tsv)

### create aks cluster
echo "Creating AKS Cluster RG"
az group create \
  --name $RG_NAME \
  --location $LOCATION \
  --tags env=lab \
  --debug

echo "Creating AKS Cluster"
if [[ $HAS_AZURE_MONITOR -eq 1 && $HAS_AUTO_SCALER -eq 1 && $HAS_MANAGED_IDENTITY -eq 1 && $HAS_NETWORK_POLICY -eq 1 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Monitor Enabled, AutoScaler, Managed Idenity and Network Policy = Azure"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $RG_NAME \
  --name $CLUSTER_NAME \
  --node-count $NODE_COUNT \
  --node-vm-size $NODE_SIZE \
  --location $LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $VMSETTYPE \
  --kubernetes-version $VERSION \
  --network-plugin $CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $ADMIN_USERNAME \
  --enable-addons monitoring \
  --network-policy azure \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3 \
  --enable-managed-identity \
  --nodepool-name sysnpool \
  --nodepool-tags "env=syspool" \
  --debug 
elif [[ $HAS_AZURE_MONITOR -eq 1 && $HAS_AUTO_SCALER -eq 1 && $HAS_MANAGED_IDENTITY -eq 1 && $HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Monitor Enabled, AutoScaler, Managed Idenity"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $RG_NAME \
  --name $CLUSTER_NAME \
  --node-count $NODE_COUNT \
  --node-vm-size $NODE_SIZE \
  --location $LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $VMSETTYPE \
  --kubernetes-version $VERSION \
  --network-plugin $CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $ADMIN_USERNAME \
  --enable-addons monitoring \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3 \
  --enable-managed-identity \
  --nodepool-name sysnpool \
  --nodepool-tags "env=syspool" \
  --debug
elif [[ $HAS_AZURE_MONITOR -eq 1 && $HAS_AUTO_SCALER -eq 1 && $HAS_MANAGED_IDENTITY -eq 0 && $HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Monitor Enabled, AutoScaler"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $RG_NAME \
  --name $CLUSTER_NAME \
  --service-principal $SP \
  --client-secret $SPPASS \
  --node-count $NODE_COUNT \
  --node-vm-size $NODE_SIZE \
  --location $LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $VMSETTYPE \
  --kubernetes-version $VERSION \
  --network-plugin $CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $ADMIN_USERNAME \
  --enable-addons monitoring \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3 \
  --nodepool-name sysnpool \
  --nodepool-tags "env=syspool" \
  --debug
elif [[ $HAS_AZURE_MONITOR -eq 1 && $HAS_AUTO_SCALER -eq 0 && $HAS_MANAGED_IDENTITY -eq 0 && $HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $RG_NAME \
  --name $CLUSTER_NAME \
  --service-principal $SP \
  --client-secret $SPPASS \
  --node-count $NODE_COUNT \
  --node-vm-size $NODE_SIZE \
  --location $LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $VMSETTYPE \
  --kubernetes-version $VERSION \
  --network-plugin $CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $ADMIN_USERNAME \
  --enable-addons monitoring \
  --nodepool-name sysnpool \
  --nodepool-tags "env=syspool" \
  --debug
elif [[ $HAS_AZURE_MONITOR -eq 0 && $HAS_AUTO_SCALER -eq 0 && $HAS_MANAGED_IDENTITY -eq 1 && $HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Managed Identity"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $RG_NAME \
  --name $CLUSTER_NAME \
  --node-count $NODE_COUNT \
  --node-vm-size $NODE_SIZE \
  --location $LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $VMSETTYPE \
  --kubernetes-version $VERSION \
  --network-plugin $CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $ADMIN_USERNAME \
  --enable-managed-identity \
  --nodepool-name sysnpool \
  --nodepool-tags "env=syspool" \
  --debug
elif [[ $HAS_AZURE_MONITOR -eq 0 && $HAS_AUTO_SCALER -eq 0 && $HAS_MANAGED_IDENTITY -eq 1 && $HAS_NETWORK_POLICY -eq 1 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Managed Identityi and Network Policy = Azure" 
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $RG_NAME \
  --name $CLUSTER_NAME \
  --node-count $NODE_COUNT \
  --node-vm-size $NODE_SIZE \
  --location $LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $VMSETTYPE \
  --kubernetes-version $VERSION \
  --network-plugin $CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $ADMIN_USERNAME \
  --enable-managed-identity \
  --network-policy azure \
  --nodepool-name sysnpool \
  --nodepool-tags "env=syspool" \
  --debug
elif [[ $HAS_AZURE_MONITOR -eq 1 && $HAS_AUTO_SCALER -eq 0 && $HAS_MANAGED_IDENTITY -eq 0 && $HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Monitor" 
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $RG_NAME \
  --name $CLUSTER_NAME \
  --service-principal $SP \
  --client-secret $SPPASS \
  --node-count $NODE_COUNT \
  --node-vm-size $NODE_SIZE \
  --location $LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $VMSETTYPE \
  --kubernetes-version $VERSION \
  --network-plugin $CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $ADMIN_USERNAME \
  --enable-addons monitoring \
  --nodepool-name sysnpool \
  --nodepool-tags "env=syspool" \
  --debug
else
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS without Monitor"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $RG_NAME \
  --name $CLUSTER_NAME \
  --service-principal $SP \
  --client-secret $SPPASS \
  --node-count $NODE_COUNT \
  --node-vm-size $NODE_SIZE \
  --location $LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $VMSETTYPE \
  --kubernetes-version $VERSION \
  --network-plugin $CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $ADMIN_USERNAME \
  --nodepool-name sysnpool \
  --nodepool-tags "env=syspool" \
  --debug
fi

## Add User nodepooll
echo 'Add Node pool type User'
az aks nodepool add \
  -g $RG_NAME \
  -n usernpool \
  --cluster-name $CLUSTER_NAME \
  --node-osdisk-type Ephemeral \
  --node-osdisk-size $USER_NODE_DISK_SIZE \
  --kubernetes-version $VERSION \
  --tags "env=userpool" \
  --mode User \
  --node-count $USER_NODE_COUNT \
  --node-vm-size $USER_NODE_SIZE \
  --debug


### Create ACR RG
echo "Creating ACR Cluster RG"
az group create \
  --name $ACR_RG_NAME \
  --location $ACR_LOCATION \
  --tags env=lab \
  --debug

### Create ACR Cluster
echo "Creating ACR Cluster"
az acr create \
  --name $ACR_NAME \
  --resource-group $ACR_RG_NAME \
  --sku Standard \
  --debug

### Give time to breath
echo "Wait a bit... 45s"
sleep 45

### Add AKS to ACR
echo "Add AKS Cluster to ACR"
az aks update \
  --name $CLUSTER_NAME \
  --resource-group $RG_NAME \
  --attach-acr $ACR_NAME \
  --debug


### Create RG for VM
### Skip if RG already been Created
echo "Create RG if required"
if [ $(az group list -o table | awk '{print $1}' | grep "^$RG_NAME" | wc -l) -eq 1 ]; then echo "RG Already there! Continue"; else  az group create --location $RG_LOCATION --name $RG_NAME; fi

### VM SSS Client subnet Creation
echo "Create VM Subnet"
az network vnet subnet create \
  -g $RG_NAME \
  --vnet-name $VNET_NAME \
  -n $VM_SUBNET_NAME \
  --address-prefixes $VM_SNET_CIDR \
  --debug


### VM NSG Create
echo "Create NSG"
az network nsg create \
  -g $RG_NAME \
  -n $VM_NSG_NAME \
  --debug

## Public IP Create
echo "Create Public IP"
az network public-ip create --name $VM_PUBLIC_IP_NAME --resource-group $RG_NAME --debug


### VM Nic Create
echo "Create VM Nic"
az network nic create \
  -g $RG_NAME \
  --vnet-name $VNET_NAME \
  --subnet $VNET_SUBNET_NAME \
  -n $VM_NIC_NAME \
  --network-security-group $VM_NSG_NAME \
  --debug 

## Attache Public IP to VM NIC
echo "Attach Public IP to VM NIC"
az network nic ip-config update \
  --name $VM_DEFAULT_IP_CONFIG \
  --nic-name $VM_NIC_NAME \
  --resource-group $RG_NAME \
  --public-ip-address $VM_PUBLIC_IP_NAME \
  --debug

## Update NSG in VM Subnet
echo "Update NSG in VM Subnet"
az network vnet subnet update \
  --resource-group $RG_NAME \
  --name $VNET_SUBNET_NAME \
  --vnet-name $VNET_NAME \
  --network-security-group $VM_NSG_NAME \
  --debug

### Create VM
echo "Create VM"
az vm create \
  --resource-group $RG_NAME \
  --authentication-type $AUTH_TYPE \
  --name $VM_NAME \
  --computer-name $VM_INTERNAL_NAME \
  --image $IMAGE \
  --size $VM_SIZE \
  --admin-username $ADMIN_USERNAME \
  --ssh-key-values $ADMIN_USERNAME_SSH_KEYS_PUB \
  --storage-sku $VM_STORAGE_SKU \
  --os-disk-size-gb $VM_OS_DISK_SIZE \
  --os-disk-name $VM_OS_DISK_NAME \
  --nics $VM_NIC_NAME \
  --tags $TAGS \
  --debug

echo "Sleeping 45s - Allow time for Public IP"
sleep 45

### Output Public IP of VM
echo "Public IP of VM is:"
#VM_PUBLIC_IP=$(az network public-ip list -g $RG_NAME --query "{ip:[].ipAddress, name:[].name, tags:[].tags.purpose}" -o json | jq -r ".ip, .name, .tags | @csv")
VM_PUBLIC_IP=$(az network public-ip list -g $RG_NAME --query "{ip:[].ipAddress}" -o json | jq -r ".ip | @csv")
VM_PUBLIC_IP_PARSED=$(echo $VM_PUBLIC_IP | sed 's/"//g')
echo $VM_PUBLIC_IP_PARSED

### Allow SSH from my Home
echo "Update VM NSG to allow SSH"
az network nsg rule create \
  --nsg-name $VM_NSG_NAME \
  --resource-group $RG_NAME \
  --name ssh_allow \
  --priority 100 \
  --source-address-prefixes $MY_HOME_PUBLIC_IP \
  --source-port-ranges '*' \
  --destination-address-prefixes $VM_PRIV_IP \
  --destination-port-ranges 22 \
  --access Allow \
  --protocol Tcp \
  --description "Allow from MY ISP IP"

### Input Key Fingerprint
echo "Input Key Fingerprint" 
#ssh-keyscan -H $VM_PUBLIC_IP_PARSED >> ~/.ssh/known_hosts
ssh-keygen -F $VM_PUBLIC_IP_PARSED >/dev/null | ssh-keyscan -H $VM_PUBLIC_IP_PARSED >> ~/.ssh/known_hosts

echo "Sleeping 45s"
sleep 45

### Copy to VM AKS SSH Priv Key
echo "Copy to VM priv Key of AKS Cluster"
scp  -o 'StrictHostKeyChecking no' -i $SSH_PRIV_KEY $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED:/home/$GENERIC_ADMIN_USERNAME/id_rsa

### Set Correct Permissions on Priv Key
echo "Set good Permissions on AKS Priv Key"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED "chmod 700 /home/$GENERIC_ADMIN_USERNAME/id_rsa"


### Get Credentials
echo "Getting Cluster Credentials"
az aks get-credentials --resource-group $RG_NAME --name $CLUSTER_NAME --overwrite-existing
echo "Public IP of the VM"
echo $VM_PUBLIC_IP_PARSED

### Create the SSH into Node Helper file
echo "Process SSH into Node into SSH VM"
AKS_1ST_NODE_IP=$(kubectl get nodes -o=wide | awk 'FNR == 2 {print $6}')
AKS_STRING_TO_DO_SSH='ssh -o ServerAliveInterval=180 -o ServerAliveCountMax=2 -i id_rsa'
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED echo "$AKS_STRING_TO_DO_SSH $GENERIC_ADMIN_USERNAME@$AKS_1ST_NODE_IP >> gtno.sh"




