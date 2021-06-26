##!/usr/bin/env bash
set -e
. ./params.sh

## Create AKS RG
echo "Create AppGtw RG"
az group create \
  --name $AKS_RG_NAME \
  --location $AKS_LOCATION \
  --debug

## Create AKS Vnet
echo "Create AKS Vnet"
az network vnet create \
   --name $AKS_MAIN_VNET_NAME \
   --resource-group $AKS_RG_NAME \
   --location $AKS_LOCATION \
   --address-prefixes $AKS_ADDRESS_PREFIX \
   --subnet-name $AKS_SUBNET_NAME \
   --subnet-prefixes $AKS_SUBNET_PREFIX \
   --debug

### Get the id of the Subnet for AKS
echo "Get the Subnet for AKS ID" 
AKS_SNET_ID=$(az network vnet subnet show -g $AKS_RG_NAME --vnet-name $AKS_MAIN_VNET_NAME --name  $AKS_SUBNET_NAME --query id -o tsv)

### Create AKS cluster
echo "Creating AKS Cluster RG"
az group create \
  --name $AKS_RG_NAME \
  --location $AKS_RG_LOCATION  \
  --tags env=lab > /dev/null 2>&1

echo "Creating AKS Cluster"
az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --enable-managed-identity \
  --node-count $AKS_NODE_COUNT \
  --node-vm-size $AKS_NODE_SIZE \
  --location $AKS_RG_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_VMSETTYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons ingress-appgw \
  --appgw-name $APPGTW_NAME \
  --appgw-subnet-cidr $APPGTW_SUBNET_CIDR \
  --debug

### VM SSH Client subnet Creation
echo "Create VM SSH Subnet"
az network vnet subnet create \
  --resource-group $AKS_RG_NAME \
  --vnet-name $AKS_MAIN_VNET_NAME \
  --name $SSH_VM_SUBNET_NAME \
  --address-prefixes $SSH_VM_SUBNET_CIDR \
  --debug

### VM NSG Create
echo "Create NSG"
az network nsg create \
  --resource-group $AKS_RG_NAME \
  --name $SSH_VM_NSG_NAME \
  --debug

## Public IP Create
echo "Create Public IP"
az network public-ip create \
  --name $SSH_VM_PUBLIC_IP_NAME \
  --resource-group $AKS_RG_NAME \
  --debug

### VM Nic Create
echo "Create VM Nic"
az network nic create \
  --resource-group $AKS_RG_NAME \
  --vnet-name $AKS_MAIN_VNET_NAME \
  --subnet $SSH_VM_SUBNET_NAME \
  --name $SSH_VM_NIC_NAME \
  --network-security-group $SSH_VM_NSG_NAME \
  --debug

## Attache Public IP to VM NIC
echo "Attach Public IP to VM NIC"
az network nic ip-config update \
  --name $SSH_VM_DEFAULT_IP_CONFIG \
  --nic-name $SSH_VM_NIC_NAME \
  --resource-group $AKS_RG_NAME \
  --public-ip-address $SSH_VM_PUBLIC_IP_NAME \
  --debug

## Update NSG in VM Subnet
echo "Update NSG in VM Subnet"
az network vnet subnet update \
  --resource-group $AKS_RG_NAME \
  --name $SSH_VM_SUBNET_NAME \
  --vnet-name $AKS_MAIN_VNET_NAME \
  --network-security-group $SSH_VM_NSG_NAME \
  --debug

### Create VM
echo "Create VM"
az vm create \
  --resource-group $AKS_RG_NAME \
  --authentication-type $SSH_VM_AUTH_TYPE \
  --name $SSH_VM_NAME \
  --computer-name $SSH_VM_INTERNAL_NAME \
  --image $SSH_VM_IMAGE \
  --size $SSH_VM_SIZE \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --ssh-key-values $ADMIN_USERNAME_SSH_KEYS_PUB \
  --storage-sku $SSH_VM_STORAGE_SKU \
  --os-disk-size-gb $SSH_VM_OS_DISK_SIZE \
  --os-disk-name $SSH_VM_OS_DISK_NAME \
  --nics $SSH_VM_NIC_NAME \
  --tags $SSH_VM_TAGS \
  --debug

echo "Sleeping 45s - Allow time for Public IP"
sleep 45

### Output Public IP of VM
echo "Public IP of VM is:"
SSH_VM_PUBLIC_IP=$(az network public-ip list -g $AKS_RG_NAME -o json | jq -r ".[] | [.ipAddress, .name] | @csv" | grep ssh | awk -F "," '{print $1}' | sed 's/"//g')
SSH_VM_PUBLIC_IP_PARSED=$(echo $SSH_VM_PUBLIC_IP)

### Allow SSH from my Home
echo "Update VM NSG to allow SSH"
az network nsg rule create \
  --nsg-name $SSH_VM_NSG_NAME \
  --resource-group $AKS_RG_NAME \
  --name ssh_allow \
  --priority 100 \
  --source-address-prefixes $MY_HOME_PUBLIC_IP \
  --source-port-ranges '*' \
  --destination-address-prefixes $SSH_VM_SUBNET_PRIV_IP \
  --destination-port-ranges 22 \
  --access Allow \
  --protocol Tcp \
  --description "Allow from MY ISP IP"

### Input Key Fingerprint
echo "Input Key Fingerprint" 
#ssh-keyscan -H $VM_PUBLIC_IP_PARSED >> ~/.ssh/known_hosts
ssh-keygen -F $SSH_VM_PUBLIC_IP_PARSED >/dev/null | ssh-keyscan -H $SSH_VM_PUBLIC_IP_PARSED >> ~/.ssh/known_hosts

echo "Sleeping 100s"
sleep 100

### Copy to VM AKS SSH Priv Key
echo "Copy to VM priv Key of AKS Cluster"
scp -o 'StrictHostKeyChecking no' -i $SSH_PRIV_KEY $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$SSH_VM_PUBLIC_IP_PARSED:/home/$GENERIC_ADMIN_USERNAME/id_rsa

### Set Correct Permissions on Priv Key
echo "Set good Permissions on AKS Priv Key"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$SSH_VM_PUBLIC_IP_PARSED "chmod 700 /home/$GENERIC_ADMIN_USERNAME/id_rsa"

### Get Credentials
echo "Getting Cluster Credentials"
az aks get-credentials --resource-group $AKS_RG_NAME --name $AKS_CLUSTER_NAME --overwrite-existing
echo "Public IP of the VM"
echo $SSH_VM_PUBLIC_IP_PARSED

