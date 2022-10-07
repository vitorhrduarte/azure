##!/usr/bin/env bash
set -e
. ./params.sh

## Create Resource Group for Cluster VNet
echo "Create RG for Cluster Vnet"
az group create \
  --name $AKS_VNET_RG \
  --location $AKS_LOCATION \
  --debug

## Create  VNet and Subnet
echo "Create Vnet and Subnet for AKS Cluster"
az network vnet create \
  --resource-group $AKS_VNET_RG \
  --name $AKS_VNET \
  --address-prefix $AKS_VNET_CIDR \
  --subnet-name $AKS_SNET \
  --subnet-prefix $AKS_SNET_CIDR \
  --debug

## Get SubNet info
echo "Getting Subnet ID"
AKS_SNET_ID=$(az network vnet subnet show \
  --resource-group $AKS_VNET_RG \
  --vnet-name $AKS_VNET \
  --name $AKS_SNET \
  --query id -o tsv)

## Create AKS Cluster
echo "Creating AKS Cluster RG"
az group create \
  --name $AKS_RG_NAME \
  --location $AKS_LOCATION \
  --tags env=lab \
  --debug

echo "Creating AKS Cluster"
if [ $HAS_AZURE_MONITOR -eq 1 ]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Monitor Enabled"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --node-count $AKS_SYS_NODE_COUNT \
  --node-vm-size $AKS_SYS_NODE_SIZE \
  --node-osdisk-size $AKS_SYS_NODE_DISK_SIZE \
  --location $AKS_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_VM_SET_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons monitoring \
  --windows-admin-password $WINDOWS_AKS_ADMIN_PASSWORD \
  --windows-admin-username $GENERIC_ADMIN_USERNAME \
  --node-osdisk-type Ephemeral \
  --nodepool-name $AKS_SYS_NODE_POOL_NAME \
  --tags "env=sysnpool" \
  --enable-managed-identity \
  --os-sku $OS_SKU \
  --zones $AKS_SYSNP_ZONES \
  --debug 
else
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS without Monitor"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --node-count $AKS_SYS_NODE_COUNT \
  --node-vm-size $AKS_SYS_NODE_SIZE \
  --node-osdisk-size $AKS_SYS_NODE_DISK_SIZE \
  --location $AKS_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_VM_SET_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --windows-admin-password $WINDOWS_AKS_ADMIN_PASSWORD \
  --windows-admin-username $GENERIC_ADMIN_USERNAME \
  --node-osdisk-type Ephemeral \
  --nodepool-name $AKS_SYS_NODE_POOL_NAME \
  --tags "env=sysnpool" \
  --enable-managed-identity \
  --os-sku $OS_SKU \
  --zones $AKS_SYS_NP_ZONES \
  --debug
fi

## Logic for VMASS only
if [[ "$AKS_VM_SET_TYPE" == "AvailabilitySet" ]]; then
  echo "Skip second Nodepool - VMAS dont have it"
else
  if [[ "$HAS_2ND_NODEPOOL"  == "1" ]]; then
  ## Add User nodepooll
  echo 'Add Node pool type User'
  az aks nodepool add \
    --resource-group $AKS_RG_NAME \
    --name $AKS_USER_NODE_POOL_NAME \
    --cluster-name $AKS_CLUSTER_NAME \
    --node-osdisk-type Ephemeral \
    --node-osdisk-size $AKS_USER_NODE_DISK_SIZE \
    --kubernetes-version $AKS_VERSION \
    --tags "env=userpool" \
    --mode User \
    --node-count $AKS_USER_NODE_COUNT \
    --node-vm-size $AKS_USER_NODE_SIZE \
    --os-sku $OS_SKU \
    --zones $AKS_USR_NP_ZONES \
    --debug
  fi  
fi

## Add Windows Node
echo "Add windows node"
az aks nodepool add \
  --resource-group $AKS_RG_NAME \
  --cluster-name $AKS_CLUSTER_NAME \
  --os-type Windows \
  --name $AKS_WINDOWS_NODE_POOL_NAME \
  --node-count $AKS_WINDOWS_NODE_POOL_NUMBER \
  --node-vm-size $AKS_SYS_NODE_SIZE \
  --node-osdisk-size  $AKS_WINDOWS_NODE_DISK_SIZE \
  --node-osdisk-type Ephemeral \
  --tags "env=winnpool" \
  --os-sku $OS_WIN_SKU \
  --zones $AKS_WIN_NP_ZONES \
  --debug

if [[ "$HAS_JUMP_VMS" == "1" ]]
then

  ## SSH VM SSH Client subnet Creation
  echo "Create VM SSH Subnet"
  az network vnet subnet create \
    --resource-group $AKS_RG_NAME \
    --vnet-name $SSH_VM_VNET_NAME \
    --name $SSH_VM_VNET_SUBNET_NAME \
    --address-prefixes $SSH_VM_SNET_CIDR \
    --debug
  
  ## Windows VM RDP Client subnet Creation
  echo "Create VM RDP Subnet"
  az network vnet subnet create \
    --resource-group $AKS_RG_NAME \
    --vnet-name $WIN_VM_VNET_NAME \
    --name $WIN_VM_VNET_SUBNET_NAME \
    --address-prefixes $WIN_VM_SNET_CIDR \
    --debug
  
  ## SSH VM SSH NSG Create
  echo "Create VM SSH NSG"
  az network nsg create \
    --resource-group $AKS_RG_NAME \
    --name $SSH_VM_NSG_NAME \
    --debug
  
  ## Windows VM RDP NSG Create
  echo "Create Windows RDP NSG"
  az network nsg create \
    --resource-group $AKS_RG_NAME \
    --name $WIN_VM_NSG_NAME \
    --debug
  
  ## SSH Public IP Create
  echo "Create SSH Public IP"
  az network public-ip create \
    --name $SSH_VM_PUBLIC_IP_NAME \
    --resource-group $AKS_RG_NAME \
    --debug
  
  ## Windows Public IP Create
  echo "Create Windows Public IP"
  az network public-ip create \
    --name $WIN_VM_PUBLIC_IP_NAME \
    --resource-group $AKS_RG_NAME \
    --debug
  
  ## SSH VM Nic Create
  echo "Create SSH VM Nic"
  az network nic create \
    --resource-group $AKS_RG_NAME \
    --vnet-name $SSH_VM_VNET_NAME \
    --subnet $SSH_VM_VNET_SUBNET_NAME \
    --name $SSH_VM_NIC_NAME \
    --network-security-group $SSH_VM_NSG_NAME \
    --debug 
  
  ## Windows VM Nic Create
  echo "Create Windows VM Nic"
  az network nic create \
    --resource-group $AKS_RG_NAME \
    --vnet-name $WIN_VM_VNET_NAME \
    --subnet $WIN_VM_VNET_SUBNET_NAME \
    --name $WIN_VM_NIC_NAME \
    --network-security-group $WIN_VM_NSG_NAME \
    --debug
  
  ## SSH Attach Public IP to VM NIC
  echo "Attach Public IP to VM NIC"
  az network nic ip-config update \
    --name $SSH_VM_DEFAULT_IP_CONFIG \
    --nic-name $SSH_VM_NIC_NAME \
    --resource-group $AKS_RG_NAME \
    --public-ip-address $SSH_VM_PUBLIC_IP_NAME \
    --debug
  
  ## Windows Attach Public IP to VM NIC
  echo "Attach Public IP to VM NIC"
  az network nic ip-config update \
    --name $WIN_VM_DEFAULT_IP_CONFIG \
    --nic-name $WIN_VM_NIC_NAME \
    --resource-group $AKS_RG_NAME \
    --public-ip-address $WIN_VM_PUBLIC_IP_NAME \
    --debug
  
  ## SSH Update NSG in VM Subnet
  echo "Update NSG in VM Subnet"
  az network vnet subnet update \
    --resource-group $AKS_RG_NAME \
    --name $SSH_VM_VNET_SUBNET_NAME \
    --vnet-name $AKS_VNET \
    --network-security-group $SSH_VM_NSG_NAME \
    --debug
  
  ## Windows Update NSG in VM Subnet
  echo "Update NSG in VM Subnet"
  az network vnet subnet update \
    --resource-group $AKS_RG_NAME \
    --name $WIN_VM_VNET_SUBNET_NAME \
    --vnet-name $AKS_VNET \
    --network-security-group $WIN_VM_NSG_NAME \
    --debug
  
  ## SSH Create VM
  echo "Create SSH VM"
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
  
  ## Windows Create VM
  echo "Create Windows VM"
  az vm create \
    --resource-group $AKS_RG_NAME \
    --name $WIN_VM_NAME \
    --image $WIN_VM_IMAGE  \
    --admin-username $GENERIC_ADMIN_USERNAME \
    --admin-password $WINDOWS_AKS_ADMIN_PASSWORD \
    --nics $WIN_VM_NIC_NAME \
    --tags $WIN_VM_TAGS \
    --computer-name $WIN_VM_INTERNAL_NAME \
    --authentication-type password \
    --size $WIN_VM_SIZE \
    --storage-sku $WIN_VM_STORAGE_SKU \
    --os-disk-size-gb $WIN_VM_OS_DISK_SIZE \
    --os-disk-name $WIN_VM_OS_DISK_NAME \
    --nsg-rule NONE \
    --debug
  
  ## SSH Output Public IP of VM
  echo "Public IP of VMs is:"
  WIN_VM_PUBLIC_IP=$(az network public-ip list --resource-group $AKS_RG_NAME -o json | jq -r ".[] | [.name, .ipAddress] | @csv" | grep rdc | awk -F "," '{print $2}')
  SSH_VM_PUBLIC_IP=$(az network public-ip list --resource-group $AKS_RG_NAME -o json | jq -r ".[] | [.name, .ipAddress] | @csv" | grep ssh | awk -F "," '{print $2}')
  
  WIN_VM_PUBLIC_IP_PARSED=$(echo $WIN_VM_PUBLIC_IP | sed 's/"//g')
  SSH_VM_PUBLIC_IP_PARSED=$(echo $SSH_VM_PUBLIC_IP | sed 's/"//g')
  
  ## SSH Allow SSH from my Home
  echo "Update VM NSG to allow SSH"
  az network nsg rule create \
    --nsg-name $SSH_VM_NSG_NAME \
    --resource-group $AKS_RG_NAME \
    --name ssh_allow \
    --priority 100 \
    --source-address-prefixes $MY_HOME_PUBLIC_IP \
    --source-port-ranges '*' \
    --destination-address-prefixes $SSH_VM_PRIV_IP \
    --destination-port-ranges 22 \
    --access Allow \
    --protocol Tcp \
    --description "Allow from MY ISP IP"
  
  
  ## WIN Allow Windows from my Home
  echo "Update VM NSG to allow RDC"
  az network nsg rule create \
    --nsg-name $WIN_VM_NSG_NAME \
    --resource-group $AKS_RG_NAME \
    --name rdc_allow \
    --priority 100 \
    --source-address-prefixes $MY_HOME_PUBLIC_IP \
    --source-port-ranges '*' \
    --destination-address-prefixes $WIN_VM_PRIV_IP \
    --destination-port-ranges 3389 \
    --access Allow \
    --protocol Tcp \
    --description "Allow from MY ISP IP"
  
  ## SSH Input Key Fingerprint
  echo "Input Key Fingerprint" 
  FINGER_PRINT_CHECK=$(ssh-keygen -F $SSH_VM_PUBLIC_IP_PARSED >/dev/null | ssh-keyscan -H $SSH_VM_PUBLIC_IP_PARSED | wc -l)
  
  while [[ "$FINGER_PRINT_CHECK" = "0" ]]
  do
      echo "not good to go: $FINGER_PRINT_CHECK"
      echo "Sleeping for 5s..."
      sleep 5
      FINGER_PRINT_CHECK=$(ssh-keygen -F $SSH_VM_PUBLIC_IP_PARSED >/dev/null | ssh-keyscan -H $SSH_VM_PUBLIC_IP_PARSED | wc -l)
  done
  
  echo "Go to go with Input Key Fingerprint"
  ssh-keygen -F $SSH_VM_PUBLIC_IP_PARSED >/dev/null | ssh-keyscan -H $SSH_VM_PUBLIC_IP_PARSED >> ~/.ssh/known_hosts
  
  
  ## SSH Copy to VM AKS SSH Priv Key
  echo "Copy to VM priv Key of AKS Cluster"
  scp  -o 'StrictHostKeyChecking no' -i $SSH_PRIV_KEY $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$SSH_VM_PUBLIC_IP_PARSED:/home/gits/id_rsa
  
  ## SSH Set Correct Permissions on Priv Key
  echo "Set good Permissions on AKS Priv Key"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$SSH_VM_PUBLIC_IP_PARSED "chmod 700 /home/gits/id_rsa"
  
  ## Install and update software
  echo "Updating VM and Stuff"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$SSH_VM_PUBLIC_IP_PARSED "sudo apt update && sudo apt upgrade -y"
  
  ## VM Install software
  echo "VM Install software"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$SSH_VM_PUBLIC_IP_PARSED sudo apt install tcpdump wget snap dnsutils -y
  
  ## Add Az Cli
  echo "Add Az Cli"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$SSH_VM_PUBLIC_IP_PARSED "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
  
  ## Install Kubectl
  echo "Install Kubectl"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$SSH_VM_PUBLIC_IP_PARSED sudo snap install kubectl --classic
  
  ## Install JQ
  echo "Install JQ"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$SSH_VM_PUBLIC_IP_PARSED sudo snap install jq
  
  ## Add Kubectl completion
  echo "Add Kubectl completion"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$SSH_VM_PUBLIC_IP_PARSED "source <(kubectl completion bash)"
  
  ## Add Win password
  echo "Add Win password"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$SSH_VM_PUBLIC_IP_PARSED "touch ~/win-pass.txt && echo "$WINDOWS_AKS_ADMIN_PASSWORD" > ~/win-pass.txt"
  
  echo ""
  echo "Public IP of Windows VM"
  echo $WIN_VM_PUBLIC_IP_PARSED
  echo ""
  echo "Public IP of Linux VM"
  echo $SSH_VM_PUBLIC_IP_PARSED
  
fi
  
## AKS Get Credentials
echo "Getting Cluster Credentials"
az aks get-credentials --resource-group $AKS_RG_NAME --name $AKS_CLUSTER_NAME --overwrite-existing
  
