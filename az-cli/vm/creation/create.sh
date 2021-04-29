##!/usr/bin/env bash
set -e
. ./params.sh

if [[ "$COJSS" == "1" ]];
then

 ###################################################################################
 ## Functions 
 ###################################################################################
 ## Coundown function
 countdown() {
   IFS=:
   set -- $*
   secs=$(( ${1#0} * 3600 + ${2#0} * 60 + ${3#0} ))
   while [ $secs -gt 0 ]
   do
     sleep 1 &
     printf "\r%02d:%02d:%02d" $((secs/3600)) $(( (secs/60)%60)) $((secs%60))
     secs=$(( $secs - 1 ))
     wait
   done
   echo
 }
 
###################################################################################
## Functions
###################################################################################


## Create Resource Group VMS
echo "Create RG for VMs Vnet"
az group create \
  --name $VMS_CORE_RG_NAME \
  --location $VMS_CORE_RG_LOCATION \
  --debug

## Create VNet and Subnet
echo "Create Vnet and Subnet for Linux Jump Server"
az network vnet create \
  --resource-group $VMS_CORE_VNET_RG \
  --name $VMS_CORE_VNET_NAME \
  --address-prefix $VMS_CORE_VNET_CIDR \
  --subnet-name $VMS_JS_LINUX_SNET_NAME \
  --subnet-prefix $VMS_JS_LINUX_SNET_CIDR \
  --debug

## Windows Jump Server Subnet Creation
echo "Create Subnet for Windows Jump Server"
az network vnet subnet create \
  --resource-group $VMS_CORE_VNET_RG  \
  --vnet-name $VMS_CORE_VNET_NAME \
  --name $VMS_JS_WIN_SNET_NAME \
  --address-prefixes $VMS_JS_WIN_SNET_CIDR \
  --debug

## K8S Servers Subnet Creation
echo "Create Subnet for K8S Servers"
az network vnet subnet create \
  --resource-group $VMS_CORE_VNET_RG  \
  --vnet-name $VMS_CORE_VNET_NAME \
  --name $VMS_K8S_SNET_NAME \
  --address-prefixes $VMS_K8S_SNET_CIDR \
  --debug

## K8S Core Subnet
echo "Create Subnet for K8S Servers"
az network vnet subnet create \
  --resource-group $VMS_CORE_VNET_RG \
  --vnet-name $VMS_CORE_VNET_NAME \
  --name $VMS_K8S_SNET_NAME \
  --address-prefixes $VMS_K8S_SNET_CIDR \
  --debug

## VM Linux Jump Server NSG Create
echo "Create Linux Jump Server NSG"
az network nsg create \
  --resource-group $VMS_CORE_VNET_RG \
  --name $LINUX_JS_NSG_NAME \
  --debug

## VM Windows Jump Server NSG Create
echo "Create Windows Jump Server NSG"
az network nsg create \
  --resource-group $VMS_CORE_VNET_RG \
  --name $WINDOWS_JS_NSG_NAME \
  --debug

## Linux Jump Server Public IP Create
echo "Create Public IP - Linux"
az network public-ip create \
  --name $LINUX_JS_PUBLIC_IP_NAME \
  --resource-group $VMS_CORE_VNET_RG \
  --debug

## Windows Jump Server Public IP Create
echo "Create Public IP - Windows"
az network public-ip create \
  --name $WINDOWS_JS_PUBLIC_IP_NAME \
  --resource-group $VMS_CORE_VNET_RG \
  --debug

## Windows VM Nic Create
echo "Create Windows VM Nic"
az network nic create \
  --resource-group $VMS_CORE_VNET_RG \
  --vnet-name $VMS_CORE_VNET_NAME \
  --subnet $VMS_JS_WIN_SNET_NAME \
  --name $WINDOWS_JS_NIC_NAME \
  --network-security-group $WINDOWS_JS_NSG_NAME \
  --debug 

## Linux VM Nic Create
echo "Create Linux VM Nic"
az network nic create \
  --resource-group $VMS_CORE_VNET_RG \
  --vnet-name $VMS_CORE_VNET_NAME \
  --subnet $VMS_JS_LINUX_SNET_NAME \
  --name $LINUX_JS_NIC_NAME \
  --network-security-group $LINUX_JS_NSG_NAME \
  --debug

## Attach Public IP to Linux VM NIC
echo "Attach Public IP to Linux VM NIC"
az network nic ip-config update \
  --name $LINUX_JS_DEFAULT_IP_CONFIG \
  --nic-name $LINUX_JS_NIC_NAME \
  --resource-group $VMS_CORE_VNET_RG \
  --public-ip-address $LINUX_JS_PUBLIC_IP_NAME \
  --debug

## Attach Public IP to Windows VM NIC
echo "Attach Public IP to Windows VM NIC"
az network nic ip-config update \
  --name $WINDOWS_JS_DEFAULT_IP_CONFIG \
  --nic-name $WINDOWS_JS_NIC_NAME \
  --resource-group $VMS_CORE_VNET_RG \
  --public-ip-address $WINDOWS_JS_PUBLIC_IP_NAME \
  --debug

## Update NSG in Linux VM Subnet
echo "Update NSG in VM Subnet"
az network vnet subnet update \
  --resource-group $VMS_CORE_VNET_RG \
  --name $VMS_JS_LINUX_SNET_NAME \
  --vnet-name $VMS_CORE_VNET_NAME \
  --network-security-group $LINUX_JS_NSG_NAME \
  --debug

## Update NSG in Windows VM Subnet
echo "Update NSG in VM Subnet"
az network vnet subnet update \
  --resource-group $VMS_CORE_VNET_RG \
  --name $VMS_JS_WIN_SNET_NAME \
  --vnet-name $VMS_CORE_VNET_NAME \
  --network-security-group $WINDOWS_JS_NSG_NAME \
  --debug

## Create Linux VM
echo "Create Linux VM"
az vm create \
  --resource-group $VMS_CORE_RG_NAME \
  --authentication-type $LINUX_JS_AUTH_TYPE \
  --name $LINUX_JS_NAME \
  --computer-name $LINUX_JS_INTERNAL_NAME \
  --image $LINUX_JS_IMAGE \
  --size $LINUX_JS_SIZE \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --ssh-key-values $ADMIN_USERNAME_SSH_KEYS_PUB \
  --storage-sku $LINUX_JS_STORAGE_SKU \
  --os-disk-size-gb $LINUX_JS_OS_DISK_SIZE \
  --os-disk-name $LINUX_JS_OS_DISK_NAME \
  --nics $LINUX_JS_NIC_NAME \
  --tags $LINUX_JS_TAGS \
  --debug

### Windows Create VM
echo "Create Windows VM"
az vm create \
  --resource-group $VMS_CORE_RG_NAME \
  --name $WINDOWS_JS_NAME \
  --image $WINDOWS_JS_IMAGE \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --admin-password $WINDOWS_AKS_ADMIN_PASSWORD \
  --nics $WINDOWS_JS_NIC_NAME \
  --tags $WINDOWS_JS_TAGS \
  --computer-name $WINDOWS_JS_INTERNAL_NAME \
  --authentication-type password \
  --size $WINDOWS_JS_SIZE \
  --storage-sku $WINDOWS_JS_STORAGE_SKU \
  --os-disk-size-gb $WINDOWS_JS_OS_DISK_SIZE \
  --os-disk-name $WINDOWS_JS_OS_DISK_NAME \
  --nsg-rule NONE \
  --debug

## Getting Public IP of Linux JS VM
echo "Getting Public IP of Linux JS VM"
LINUX_JS_AZ_PUBLIC_IP=$(az network public-ip list \
  --resource-group $VMS_CORE_RG_NAME \
  --output json | jq --arg pip $LINUX_JS_PUBLIC_IP_NAME -r '.[] | select( .name == $pip ) | [ .ipAddress ] | @tsv')

## Getting Public IP of Windows JS VM
echo "Getting Public IP of Linux JS VM"
WINDOWS_JS_AZ_PUBLIC_IP=$(az network public-ip list \
  --resource-group $VMS_CORE_RG_NAME \
  --output json | jq --arg pip $WINDOWS_JS_PUBLIC_IP_NAME -r '.[] | select( .name == $pip ) | [ .ipAddress ] | @tsv')

PROCESS_NSG_FOR_LINUX_VM="true"
TIME=$SECONDS

## Get Priv IP of Linux JS VM
echo "Getting Linux JS VM Priv IP"
LINUX_JS_PRIV_IP=$(az vm list-ip-addresses --resource-group $VMS_CORE_RG_NAME --name $LINUX_JS_NAME --output json | jq -r ".[] | [ .virtualMachine.network.privateIpAddresses[0] ] | @tsv")

## Get Priv IP of Windows JS VM
echo "Getting Windows JS VM Priv IP"
WINDOWS_JS_PRIV_IP=$(az vm list-ip-addresses --resource-group $VMS_CORE_RG_NAME --name $WINDOWS_JS_NAME --output json | jq -r ".[] | [ .virtualMachine.network.privateIpAddresses[0] ] | @tsv")

while :
do
  if [ -z "$LINUX_JS_AZ_PUBLIC_IP" ];
  then
    echo "$LINUX_JS_AZ_PUBLIC_IP is empty..."
  else
    echo "Loop: $LINUX_JS_AZ_PUBLIC_IP"
    echo "VM service external IP is $LINUX_JS_AZ_PUBLIC_IP"  
    printf '%dh:%dm:%ds\n' $(($TIME/3600)) $(($TIME%3600/60)) $(($TIME%60))
 
    echo "Process NSG: $PROCESS_NSG_FOR_LINUX_VM"  
 
    ## Just Update VM NSG once=
    if [[ "$PROCESS_NSG_FOR_LINUX_VM" == "true" ]];
    then
      ## Allow SSH from my Home to Linux JS VM
      echo "Update Linux JS VM NSG to allow SSH"
      az network nsg rule create \
        --nsg-name $LINUX_JS_NSG_NAME \
        --resource-group $VMS_CORE_RG_NAME \
        --name ssh_allow \
        --priority 100 \
        --source-address-prefixes $MY_HOME_PUBLIC_IP \
        --source-port-ranges '*' \
        --destination-address-prefixes $LINUX_JS_PRIV_IP \
        --destination-port-ranges 22 \
        --access Allow \
        --protocol Tcp \
        --description "Allow from MY ISP IP"
    fi
 
    echo "Process NSG: $PROCESS_NSG_FOR_LINUX_VM"   
    ## Just update NG once
    PROCESS_NSG_FOR_VM="false"
    echo "Process NSG: $PROCESS_NSG_FOR_LINUX_VM"  

    ## Checking SSH connectivity
    echo "Testing SSH Conn..."
    echo "Enter 2nd Loop..." 

    while :
    do
      if [ "$(ssh -i "$SSH_PRIV_KEY" -o 'StrictHostKeyChecking no' -o "BatchMode=yes" -o "ConnectTimeout 5" $GENERIC_ADMIN_USERNAME@$LINUX_JS_AZ_PUBLIC_IP  echo up 2>&1)" == "up" ];
      then
        echo "Can connect to $LINUX_JS_AZ_PUBLIC_IP, continue"
        break
      else
        echo "Keep trying...."
       fi  
     done
    
     echo "Exist 1srt While loop...."
     break
  fi  

  countdown "00:00:45"

  LINUX_JS_AZ_PUBLIC_IP=$(az network public-ip list \
    --resource-group $VMS_CORE_RG_NAME \
    --output json | jq --arg pip $LINUX_JS_PUBLIC_IP_NAME -r '.[] | select( .name == $pip ) | [ .ipAddress ] | @tsv')
done

## Insert Priv Key in Linux JS VM for accessing K8S Machines
echo "Copy to VM priv Key of AKS Cluster"
scp  -o 'StrictHostKeyChecking no' -i $SSH_PRIV_KEY $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$LINUX_JS_AZ_PUBLIC_IP:/home/$GENERIC_ADMIN_USERNAME/id_rsa
 
### Set Correct Permissions on Priv Key
echo "Set good Permissions on AKS Priv Key"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$LINUX_JS_AZ_PUBLIC_IP "chmod 700 /home/$GENERIC_ADMIN_USERNAME/id_rsa"

STRING_TO_DO_SSH='ssh -o ServerAliveInterval=180 -o ServerAliveCountMax=2 -i id_rsa'
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$LINUX_JS_AZ_PUBLIC_IP echo "$STRING_TO_DO_SSH >> gtnode.sh"

## Input Key Fingerprint
echo "Linux JS Input Key Fingerprint" 
ssh-keygen -F $LINUX_JS_AZ_PUBLIC_IP >/dev/null | ssh-keyscan -H $LINUX_JS_AZ_PUBLIC_IP >> ~/.ssh/known_hosts

## Allow RDC from my Home to Windows JS VM
echo "Update Windows JS VM NSG to allow RDP"
az network nsg rule create \
  --nsg-name $WINDOWS_JS_NSG_NAME \
  --resource-group $VMS_CORE_RG_NAME \
  --name rdc_allow \
  --priority 100 \
  --source-address-prefixes $MY_HOME_PUBLIC_IP \
  --source-port-ranges '*' \
  --destination-address-prefixes $WINDOWS_JS_PRIV_IP \
  --destination-port-ranges 3389 \
  --access Allow \
  --protocol Tcp \
  --description "Allow from MY ISP IP"


echo ""
echo "Windows JS VM Public IP: $WINDOWS_JS_AZ_PUBLIC_IP"
echo ""
echo "Linux JS VM Public IP: $LINUX_JS_AZ_PUBLIC_IP"
echo ""

fi

if [[ "$COK8SS" == "1"  ]];
then

# Create Single Control Plane k8s
# Create Linux VM
echo "Create VM"
az vm create \
  --resource-group $VMS_CORE_RG_NAME \
  --authentication-type $LINUX_JS_AUTH_TYPE \
  --name $K8S_CONTROL_PLANE_NAME \
  --computer-name $K8S_CONTROL_PLANE_NAME \
  --image $LINUX_JS_IMAGE \
  --size $LINUX_JS_SIZE \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --ssh-key-values $ADMIN_USERNAME_SSH_KEYS_PUB \
  --storage-sku $LINUX_JS_STORAGE_SKU \
  --os-disk-size-gb $LINUX_JS_OS_DISK_SIZE \
  --os-disk-name $K8S_CONTROL_PLANE_OS_DISK_NAME \
  --vnet-name $VMS_CORE_VNET_NAME \
  --public-ip-address "" \
  --subnet $VMS_K8S_SNET_NAME \
  --tags $LINUX_JS_TAGS \
  --debug

## Create 3 Worker nodes
for i in {1..3}
do 
  ## Create Linux VM
  echo "Create VM"
  az vm create \
    --resource-group $VMS_CORE_RG_NAME \
    --authentication-type $LINUX_JS_AUTH_TYPE \
    --name "$K8S_WORKER_NODES_NAME$i" \
    --computer-name "$K8S_WORKER_NODES_NAME$i" \
    --image $LINUX_JS_IMAGE \
    --size $LINUX_JS_SIZE \
    --admin-username $GENERIC_ADMIN_USERNAME \
    --ssh-key-values $ADMIN_USERNAME_SSH_KEYS_PUB \
    --storage-sku $LINUX_JS_STORAGE_SKU \
    --os-disk-size-gb $LINUX_JS_OS_DISK_SIZE \
    --os-disk-name "$K8S_WORKER_NODES_NAME$i$K8S_WORKER_NODES_OS_DISK_NAME$i" \
    --vnet-name $VMS_CORE_VNET_NAME \
    --public-ip-address "" \
    --subnet $VMS_K8S_SNET_NAME \
    --tags $LINUX_JS_TAGS \
    --debug
done

fi

echo "END"

