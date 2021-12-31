##!/usr/bin/env bash
set -e
. ./params.sh

## Create Resource Group for Jump AKS VNet
echo "Configuring Networking for Jump AKS Vnet"
az group create \
  --name $LJ_USERS_RG \
  --location $AKS_LOCATION \
  --debug

## Create Jump VNet and SubNet
echo "Create Jump Box Vnet and Subnet"
az network vnet create \
  --resource-group $LJ_USERS_RG \
  --name $LJ_USERS_VNET \
  --address-prefix $LJ_USERS_VNET_CIDR \
  --subnet-name $LJ_USERS_SNET \
  --subnet-prefix $LJ_USERS_SNET_CIDR \
  --debug

## Create Resource Group for AKS VNet
echo "Create RG for AKS Vnet"
az group create \
  --name $AKS_VNET_RG \
  --location $AKS_LOCATION \
  --debug

## Create AKS VNet and SubNet
echo "Create AKS Vnet and Subnet"
az network vnet create \
  --resource-group $AKS_VNET_RG \
  --name $AKS_VNET \
  --address-prefix $AKS_VNET_CIDR \
  --subnet-name $AKS_SNET \
  --subnet-prefix $AKS_SNET_CIDR \
  --debug


## Peering Part
echo "Configuring Peering - GET ID's"
VNET_SOURCE_ID=$(az network vnet show \
  --resource-group $AKS_VNET_SOURCE_RG \
  --name $AKS_VNET_SOURCE \
  --query id \
  -o tsv)

VNET_DEST_ID=$(az network vnet show \
  --resource-group $LJ_VNET_DEST_RG \
  --name $LJ_VNET_DEST \
  --query id \
  -o tsv)

echo "Peering VNet - AKS-JBOX"
az network vnet peering create \
  --resource-group $AKS_VNET_SOURCE_RG \
  --name "${AKS_VNET_SOURCE}-to-${LJ_VNET_DEST}" \
  --vnet-name $AKS_VNET_SOURCE \
  --remote-vnet $VNET_DEST_ID \
  --allow-vnet-access \
  --debug

echo "Peering Vnet - JBOX-AKS"
az network vnet peering create \
  --resource-group $LJ_VNET_DEST_RG \
  --name "${LJ_VNET_DEST}-to-${AKS_VNET_SOURCE}" \
  --vnet-name $LJ_VNET_DEST \
  --remote-vnet $VNET_SOURCE_ID \
  --allow-vnet-access \
  --debug

## Get Subnet Info
echo "configuring Private AKS"
echo "Getting Subnet ID"
AKS_SNET_ID=$(az network vnet subnet show \
  --resource-group $AKS_VNET_RG \
  --vnet-name $AKS_VNET \
  --name $AKS_SNET \
  --query id -o tsv)

### create private aks cluster
echo "Creating Private AKS Cluster RG"
az group create \
  --name $AKS_RG_NAME \
  --location $AKS_LOCATION \
  --debug 

## AKS Private Cluster Creation
echo "Creating Private AKS Cluster"
az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --service-principal $SP \
  --client-secret $SPPASS \
  --kubernetes-version $AKS_VERSION \
  --location $AKS_LOCATION \
  --enable-private-cluster \
  --node-vm-size $AKS_NODE_SIZE \
  --load-balancer-sku standard \
  --node-count $AKS_NODE_COUNT \
  --node-osdisk-size $AKS_NODE_DISK_SIZE \
  --network-plugin $AKS_CNI_PLUGIN \
  --vnet-subnet-id $AKS_SNET_ID \
  --docker-bridge-address $AKS_DOCKER_BRIDGE_ADDRESS \
  --dns-service-ip $AKS_DNS_SERVICE \
  --service-cidr $AKS_SERVICE_CIDR \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --windows-admin-password $WINDOWS_AKS_ADMIN_PASSWORD \
  --windows-admin-username $GENERIC_ADMIN_USERNAME 
#  --network-policy calico \
#  --zone 1 2 \
#  --debug 

## Configure Private DNS Link to Jumpbox VM
echo "Configuring Private DNS Link to Jumpbox VM"
NODE_RG=$(az aks show --name $AKS_CLUSTER_NAME \
  --resource-group $AKS_RG_NAME \
  --query 'nodeResourceGroup' -o tsv) 

DNS_ZONE=$(az network private-dns zone list \
  --resource-group $NODE_RG \
  --query [0].name -o tsv)

az network private-dns link vnet create \
  --name "${LJ_USERS_VNET}-${LJ_USERS_RG}" \
  --resource-group $NODE_RG \
  --virtual-network $VNET_DEST_ID \
  --zone-name $DNS_ZONE \
  --registration-enabled false \
  --debug  

## Setup Jumbox VM
echo "configuring Jumbox VM"
## Create Subnet for VM
echo "Creating Jumpbox subnet"
az network vnet subnet create \
  --name $LJ_USERS_VNET \
  --resource-group $LJ_USERS_RG \
  --vnet-name $LJ_VM_VNET \
  --address-prefix $LJ_VM_SNET_CIDR \
  --debug

## Get Subnet Info
echo "Getting Subnet ID"
VM_SNET_ID=$(az network vnet subnet show \
  --resource-group $LJ_VM_RG \
  --vnet-name $LJ_VM_VNET \
  --name $LJ_VM_SNET \
  --query id -o tsv)

## Create Public IP
echo "Creating VM public IP"
az network public-ip create \
  --resource-group $LJ_VM_RG \
  --name $LJ_VM_PUBIP \
  --allocation-method dynamic \
  --sku basic \
  --debug

## Create VM
echo "Creating the VM"
az vm create \
  --resource-group $LJ_VM_RG \
  --name $LJ_VM_NAME \
  --image $LJ_IMAGE \
  --size $LJ_VM_SIZE \
  --os-disk-size-gb $LJ_VM_OSD_SIZE \
  --subnet $VM_SNET_ID \
  --public-ip-address $LJ_VM_PUBIP \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --ssh-key-values $ADMIN_USERNAME_SSH_KEYS_PUB \
  --authentication-type $LJ_AUTH_TYPE \
  --debug


## Output Public IP of VM
VM_PUBLIC_IP=$(az network public-ip show \
  --name $LJ_VM_PUBIP \
  --resource-group $LJ_VM_RG \
  --query ipAddress \
  --output tsv)
echo $VM_PUBLIC_IP

## Get Finger Print
echo "Get Finger Print"
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

## Access VM
echo "Access VM" 
ssh $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP -i $SSH_PRIV_KEY

