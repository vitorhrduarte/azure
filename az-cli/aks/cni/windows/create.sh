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
if [ $HAS_AZURE_MONITOR -eq 1 ]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Monitor Enabled"
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
  --enable-addons monitoring \
  --windows-admin-password $WINDOWS_AKS_ADMIN_PASSWORD \
  --windows-admin-username $WINDOWS_ADMIN_USER \
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
  --windows-admin-password $WINDOWS_AKS_ADMIN_PASSWORD \
  --windows-admin-username $WINDOWS_ADMIN_USER \
  --debug
fi


echo "Waiting 30s"
sleep 30

## Add Windows Node
echo "Add windows node"
az aks nodepool add \
    --resource-group $RG_NAME \
    --cluster-name $CLUSTER_NAME \
    --os-type Windows \
    --name $WINDOWS_NODE_POOL_NAME \
    --node-count $WINDOWS_NODE_POOL_NUMBER \
    --node-vm-size $NODE_SIZE \
    --debug

### SSH Create RG for VM
### Skip if RG already been Created
echo "Create RG if required"
if [ $(az group list -o table | awk '{print $1}' | grep "^$RG_NAME" | wc -l) -eq 1 ]; then echo "RG Already there! Continue"; else  az group create --location $RG_LOCATION --name $RG_NAME; fi

### SSH VM SSH Client subnet Creation
echo "Create VM SSH Subnet"
az network vnet subnet create \
  -g $RG_NAME \
  --vnet-name $VNET_NAME \
  -n $VM_SUBNET_NAME \
  --address-prefixes $VM_SNET_CIDR \
  --debug

### Windows VM RDP Client subnet Creation
echo "Create VM RDP Subnet"
az network vnet subnet create \
  -g $RG_NAME \
  --vnet-name $WIN_VNET_NAME \
  -n $WIN_VM_SUBNET_NAME \
  --address-prefixes $WIN_VM_SNET_CIDR \
  --debug

### SSH VM SSH NSG Create
echo "Create VM SSH NSG"
az network nsg create \
  -g $RG_NAME \
  -n $VM_NSG_NAME \
  --debug

### Windows VM RDP NSG Create
echo "Create Windows RDP NSG"
az network nsg create \
  -g $RG_NAME \
  -n $WIN_VM_NSG_NAME \
  --debug

### SSH Public IP Create
echo "Create SSH Public IP"
az network public-ip create \
  --name $VM_PUBLIC_IP_NAME \
  --resource-group $RG_NAME \
  --debug

### Windows Public IP Create
echo "Create Windows Public IP"
az network public-ip create \
  --name $WIN_VM_PUBLIC_IP_NAME \
  --resource-group $RG_NAME \
  --debug

### SSH VM Nic Create
echo "Create SSH VM Nic"
az network nic create \
  -g $RG_NAME \
  --vnet-name $VNET_NAME \
  --subnet $VNET_SUBNET_NAME \
  -n $VM_NIC_NAME \
  --network-security-group $VM_NSG_NAME \
  --debug 

### Windows VM Nic Create
echo "Create Windows VM Nic"
az network nic create \
  -g $RG_NAME \
  --vnet-name $VNET_NAME \
  --subnet $WIN_VNET_SUBNET_NAME \
  -n $WIN_VM_NIC_NAME \
  --network-security-group $WIN_VM_NSG_NAME \
  --debug

### SSH Attach Public IP to VM NIC
echo "Attach Public IP to VM NIC"
az network nic ip-config update \
  --name $VM_DEFAULT_IP_CONFIG \
  --nic-name $VM_NIC_NAME \
  --resource-group $RG_NAME \
  --public-ip-address $VM_PUBLIC_IP_NAME \
  --debug


### Windows Attach Public IP to VM NIC
echo "Attach Public IP to VM NIC"
az network nic ip-config update \
  --name $WIN_VM_DEFAULT_IP_CONFIG \
  --nic-name $WIN_VM_NIC_NAME \
  --resource-group $RG_NAME \
  --public-ip-address $WIN_VM_PUBLIC_IP_NAME \
  --debug



### SSH Update NSG in VM Subnet
echo "Update NSG in VM Subnet"
az network vnet subnet update \
  --resource-group $RG_NAME \
  --name $VNET_SUBNET_NAME \
  --vnet-name $VNET_NAME \
  --network-security-group $VM_NSG_NAME \
  --debug

### Windows Update NSG in VM Subnet
echo "Update NSG in VM Subnet"
az network vnet subnet update \
  --resource-group $RG_NAME \
  --name $WIN_VNET_SUBNET_NAME \
  --vnet-name $VNET_NAME \
  --network-security-group $WIN_VM_NSG_NAME \
  --debug

### SSH Create VM
echo "Create SSH VM"
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

### Windows Create VM
echo "Create Windows VM"
az vm create \
  --resource-group $RG_NAME \
  --name $WIN_VM_NAME \
  --image $WIN_IMAGE  \
  --admin-username $ADMIN_USERNAME \
  --admin-password $WINDOWS_AKS_ADMIN_PASSWORD \
  --nics $WIN_VM_NIC_NAME \
  --tags $WIN_TAGS \
  --computer-name $WIN_VM_INTERNAL_NAME \
  --authentication-type password \
  --size $WIN_VM_SIZE \
  --storage-sku $WIN_VM_STORAGE_SKU \
  --os-disk-size-gb $WIN_VM_OS_DISK_SIZE \
  --os-disk-name $WIN_VM_OS_DISK_NAME \
  --nsg-rule NONE \
  --debug

### SSH Output Public IP of VM
echo "Public IP of VM is:"
#VM_PUBLIC_IP=$(az network public-ip list -g $RG_NAME --query "{ip:[].ipAddress, name:[].name, tags:[].tags.purpose}" -o json | jq -r ".ip, .name, .tags | @csv")
WIN_VM_PUBLIC_IP=$(az network public-ip list -g $RG_NAME -o json | jq -r ".[] | [.name, .ipAddress] | @csv" | grep rdc | awk -F "," '{print $2}')
SSH_VM_PUBLIC_IP=$(az network public-ip list -g $RG_NAME -o json | jq -r ".[] | [.name, .ipAddress] | @csv" | grep ssh | awk -F "," '{print $2}')

WIN_VM_PUBLIC_IP_PARSED=$(echo $WIN_VM_PUBLIC_IP | sed 's/"//g')
SSH_VM_PUBLIC_IP_PARSED=$(echo $SSH_VM_PUBLIC_IP | sed 's/"//g')

### SSH Allow SSH from my Home
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


### WIN Allow Windows from my Home
echo "Update VM NSG to allow RDC"
az network nsg rule create \
  --nsg-name $WIN_VM_NSG_NAME \
  --resource-group $RG_NAME \
  --name rdc_allow \
  --priority 100 \
  --source-address-prefixes $MY_HOME_PUBLIC_IP \
  --source-port-ranges '*' \
  --destination-address-prefixes $WIN_VM_PRIV_IP \
  --destination-port-ranges 3389 \
  --access Allow \
  --protocol Tcp \
  --description "Allow from MY ISP IP"

### SSH Input Key Fingerprint
echo "Input Key Fingerprint" 
#ssh-keyscan -H $VM_PUBLIC_IP_PARSED >> ~/.ssh/known_hosts
ssh-keygen -F $SSH_VM_PUBLIC_IP_PARSED >/dev/null | ssh-keyscan -H $SSH_VM_PUBLIC_IP_PARSED >> ~/.ssh/known_hosts

echo "Sleeping 45s"
sleep 45

### SSH Copy to VM AKS SSH Priv Key
echo "Copy to VM priv Key of AKS Cluster"
scp  -o 'StrictHostKeyChecking no' -i /home/gits/azure/vm/ssh-keys/id_rsa /home/gits/azure/vm/ssh-keys/id_rsa gits@$SSH_VM_PUBLIC_IP_PARSED:/home/gits/id_rsa

### SSH Set Correct Permissions on Priv Key
echo "Set good Permissions on AKS Priv Key"
ssh -i /home/gits/azure/vm/ssh-keys/id_rsa gits@$SSH_VM_PUBLIC_IP_PARSED "chmod 700 /home/gits/id_rsa"

### Install and update software
echo "Updating VM and Stuff"
ssh -i /home/gits/azure/vm/ssh-keys/id_rsa gits@$SSH_VM_PUBLIC_IP_PARSED "sudo apt update && sudo apt upgrade -y"

### Add Win password
ssh -i /home/gits/azure/vm/ssh-keys/id_rsa gits@$SSH_VM_PUBLIC_IP_PARSED "touch ~/win-pass.txt && echo "$WINDOWS_AKS_ADMIN_PASSWORD" > ~/win-pass.txt"

### AKS Get Credentials
echo "Getting Cluster Credentials"
az aks get-credentials --resource-group $RG_NAME --name $CLUSTER_NAME --overwrite-existing


echo ""
echo "Public IP of Windows VM"
echo $WIN_VM_PUBLIC_IP_PARSED
echo ""
echo "Public IP of Linux VM"
echo $SSH_VM_PUBLIC_IP_PARSED
echo ""
echo "Primaty IP of the VMSS nodes"
#az vmss nic list -g  MC_RG-AKS-LAB_AKS-LAB_WESTEUROPE --vmss-name aks-nodepool1-51898505-vmss -o json | jq -r ".[].ipConfigurations[] | select(.primary==true)  | [.privateIpAddress, .name] | @csv" | awk -F "," '{print $1}' | sed 's/"//g'
