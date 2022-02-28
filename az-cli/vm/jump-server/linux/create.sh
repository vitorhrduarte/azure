##!/usr/bin/env bash
set -e
. ./params.sh


## Create RG
echo "Create RG"
az group create \
  --name $JS_MAIN_VNET_RG \
  --location $JS_MAIN_VNET_LOCATION \
  --debug


## Create VNet and Subnet
echo "Create Vnet for Jump Server"
az network vnet create \
  --resource-group $JS_MAIN_VNET_RG \
  --name $JS_MAIN_VNET_NAME \
  --address-prefix $JS_MAIN_VNET_CIDR \
  --debug


## VM Linux Jump Server Creation
echo "Create VM Linux Jump Server Subnet"
az network vnet subnet create \
  --resource-group $JS_MAIN_VNET_RG \
  --vnet-name $JS_MAIN_VNET_NAME \
  --name $JS_SUBNET_NAME \
  --address-prefixes $JS_SUBNET_CIDR \
  --debug


## Public IP Create
echo "Create Public IP"
az network public-ip create \
  --name $JS_PUBLIC_IP_NAME \
  --resource-group $JS_MAIN_VNET_RG \
  --debug


## VM Nic Create
echo "Create VM Nic"
az network nic create \
  --resource-group $JS_MAIN_VNET_RG \
  --vnet-name $JS_MAIN_VNET_NAME \
  --subnet $JS_SUBNET_NAME \
  --name $JS_NIC_NAME \
  --debug 


## Attach Public IP to VM NIC
echo "Attach Public IP to VM NIC"
az network nic ip-config update \
  --name $JS_DEFAULT_IP_CONFIG \
  --nic-name $JS_NIC_NAME \
  --resource-group $JS_MAIN_VNET_RG \
  --public-ip-address $JS_PUBLIC_IP_NAME \
  --debug


## Create VM
echo "Create VM"
az vm create \
  --resource-group $JS_MAIN_VNET_RG \
  --authentication-type $JS_AUTH_TYPE \
  --name $JS_NAME \
  --computer-name $JS_INTERNAL_NAME \
  --image $JS_IMAGE \
  --size $JS_SIZE \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --ssh-key-values $ADMIN_USERNAME_SSH_KEYS_PUB \
  --storage-sku $JS_STORAGE_SKU \
  --os-disk-size-gb $JS_OS_DISK_SIZE \
  --os-disk-name $JS_OS_DISK_NAME \
  --nics $JS_NIC_NAME \
  --tags $JS_TAGS \
  --debug


## Process if NSG is required
if [[ "$JS_HAS_NSG" == "1" ]]
then

  ## Create NSG
  echo "Create NSG"
  az network nsg create \
    --resource-group $JS_MAIN_VNET_RG\
    --name $JS_NSG_NAME \
    --debug


  ## Update NSG in VM Subnet
  echo "Update NSG in VM Subnet"
  az network vnet subnet update \
    --resource-group $JS_MAIN_VNET_RG \
    --name $JS_SUBNET_NAME \
    --vnet-name $JS_MAIN_VNET_NAME \
    --network-security-group $JS_NSG_NAME \
    --debug

fi


## Waiting for PIP
VM_PUBLIC_IP=$(az network public-ip list \
  --resource-group $JS_MAIN_VNET_RG \
  --output json | jq -r ".[] | select (.name==\"$JS_PUBLIC_IP_NAME\") | [ .ipAddress] | @tsv" | wc -l)

while [[ "$VM_PUBLIC_IP" = "0" ]]
do
   echo "Not Good to Go: " $VM_PUBLIC_IP
   echo "Sleeping for 2s..."
   sleep 2s
   VM_PUBLIC_IP=$(az network public-ip list \
     --resource-group $JS_MAIN_VNET_RG \
     --output json | jq -r ".[] | select (.name==\"$JS_PUBLIC_IP_NAME\") | [ .ipAddress] | @tsv" | wc -l)
done

VM_PUBLIC_IP=$(az network public-ip list \
  --resource-group $JS_MAIN_VNET_RG \
  --output json | jq -r ".[] | select (.name==\"$JS_PUBLIC_IP_NAME\") | [ .ipAddress] | @tsv")


## Process if NSG is required
if [[ "$JS_HAS_NSG" == "1" ]]
then
  ## Allow SSH from my Home
  echo "Update VM NSG to allow SSH"
  az network nsg rule create \
    --nsg-name $JS_NSG_NAME \
    --resource-group $JS_MAIN_VNET_RG \
    --name ssh_allow \
    --priority 100 \
    --source-address-prefixes $JS_MY_ISP_IP \
    --source-port-ranges '*' \
    --destination-address-prefixes $JS_PRIV_IP \
    --destination-port-ranges 22 \
    --access Allow \
    --protocol Tcp \
    --description "Allow from MY ISP IP"

fi


## Jit Handling for VM
echo "Jit Handling for VM"
if [[ "$JS_USE_JIT" == "1" ]]
then
   
    ## Azure VM works with Upper case RG
    JS_RG_UPPER=${JS_MAIN_VNET_RG^^}

    echo "Create JIT"
    bash ./jit.sh -o create -m $JS_INTERNAL_NAME -g $JS_RG_UPPER -p 22
    echo ""
    echo "Sleeping for 15s"
    sleep 15
    echo ""
    echo "Initiate JIT"
    bash ./jit.sh -o init -m $JS_INTERNAL_NAME -g $JS_RG_UPPER -p 22
fi


if [[ "$JS_UPDATE" == "1" ]]
then 

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
  
  
  ## Good to go with Input Key Fingerprint
  echo "Good to go with Input Key Fingerprint"
  ssh-keygen -F $VM_PUBLIC_IP >/dev/null | ssh-keyscan -H $VM_PUBLIC_IP >> ~/.ssh/known_hosts
  
  
  ## Copy to VM AKS SSH Priv Key
  echo "Copy to VM priv Key of AKS Cluster"
  scp -o 'StrictHostKeyChecking no' -i $SSH_PRIV_KEY $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP:/home/$GENERIC_ADMIN_USERNAME/id_rsa


  ## Set Correct Permissions on Priv Key
  echo "Set good Permissions on AKS Priv Key"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP "chmod 700 /home/$GENERIC_ADMIN_USERNAME/id_rsa"
  
  
  ## Add ssh helper file
  echo "Add SSH Helper File"
  AKS_STRING_TO_DO_SSH='ssh -o ServerAliveInterval=180 -o ServerAliveCountMax=2'
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP echo "$AKS_STRING_TO_DO_SSH $GENERIC_ADMIN_USERNAME@$AKS_1ST_NODE_IP >> gtno.sh"
  
  
  ## Update Server VM
  echo "Update Server VM"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP sudo apt update && sudo apt upgrade -y
  
  
  ## VM Install software
  echo "VM Install software"
  ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP sudo apt install tcpdump wget dialog snapd dnsutils -y
  

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

fi
