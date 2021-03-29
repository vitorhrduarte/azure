##!/usr/bin/env bash
set -e
. ./params.sh


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



## Create ML RG
echo "Creating RG for ML workspace"
az group create \
  --name $ML_RG_NAME \
  --location $ML_RG_LOCATION \
  --debug

## Create ML WorkSpace
echo "Creating WorkSpace for ML"
az ml workspace create \
  --workspace-name $ML_WORK_SPACE_NAME \
  --location $ML_RG_LOCATION \
  --resource-group $ML_RG_NAME \
  --debug

## Create  VNet and Subnet for AKS
echo "Create Vnet and Subnet for AKS Cluster"
az network vnet create \
    -g $ML_RG_NAME \
    -n $AKS_VNET_NAME \
    --address-prefix $AKS_VNET_ADDRESS_PREFIX \
    --subnet-name $AKS_VNET_SUBNET_NAME \
    --subnet-prefix $AKS_VNET_SUBNET_PREFIX \
    --debug

## Create AKS for ML from ML side
echo "Creating AKS"
az ml computetarget create aks \
  --name $AKS_NAME \
  --resource-group $ML_RG_NAME \
  --workspace-name $ML_WORK_SPACE_NAME \
  --agent-count $AKS_NODE_COUNT \
  --load-balancer-type $AKS_LB_TYPE \
  --location $AKS_RG_LOCATION \
  --cluster-purpose $AKS_ML_PURPOSE \
  --vm-size $AKS_ML_VM_SIZE \
  --dns-service-ip $AKS_DNS_SERVICE_IP \
  --docker-bridge-cidr $AKS_DOCKER_BRIDGE_IP \
  --service-cidr $AKS_SERVICE_CIDR \
  --subnet-name $AKS_VNET_SUBNET_NAME \
  --vnet-name $AKS_VNET_NAME \
  --vnet-resourcegroup-name $ML_RG_NAME \
  --debug

## VM SSH Client subnet Creation
echo "Create VM Subnet"
az network vnet subnet create \
  --resource-group $ML_RG_NAME \
  --vnet-name $AKS_VNET_NAME \
  --name $VM_SUBNET_NAME \
  --address-prefixes $VM_SNET_CIDR \
  --debug

## VM NSG Create
echo "Create NSG"
az network nsg create \
  --resource-group $ML_RG_NAME \
  --name $VM_NSG_NAME \
  --debug

## Public IP Create
echo "Create Public IP"
az network public-ip create \
  --name $VM_PUBLIC_IP_NAME \
  --resource-group $ML_RG_NAME \
  --debug

## VM Nic Create
echo "Create VM Nic"
az network nic create \
  --resource-group $ML_RG_NAME \
  --vnet-name $AKS_VNET_NAME \
  --subnet $VM_SUBNET_NAME \
  --name $VM_NIC_NAME \
  --network-security-group $VM_NSG_NAME \
  --debug

## Attach Public IP to VM NIC
echo "Attach Public IP to VM NIC"
az network nic ip-config update \
  --name $VM_DEFAULT_IP_CONFIG \
  --nic-name $VM_NIC_NAME \
  --resource-group $ML_RG_NAME \
  --public-ip-address $VM_PUBLIC_IP_NAME \
  --debug

## Update NSG in VM Subnet
echo "Update NSG in VM Subnet"
az network vnet subnet update \
  --resource-group $ML_RG_NAME \
  --name $VM_SUBNET_NAME \
  --vnet-name $AKS_VNET_NAME \
  --network-security-group $VM_NSG_NAME \
  --debug

## Create VM
echo "Create VM"
az vm create \
  --resource-group $ML_RG_NAME \
  --authentication-type $VM_AUTH_TYPE \
  --name $VM_NAME \
  --computer-name $VM_INTERNAL_NAME \
  --image $VM_IMAGE \
  --size $VM_SIZE \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --ssh-key-values $ADMIN_USERNAME_SSH_KEYS_PUB \
  --storage-sku $VM_STORAGE_SKU \
  --os-disk-size-gb $VM_OS_DISK_SIZE \
  --os-disk-name $VM_OS_DISK_NAME \
  --nics $VM_NIC_NAME \
  --tags $TAGS \
  --debug

## Output Public IP of VM
TIME=$SECONDS
VM_PUBLIC_IP=$(az network public-ip list -g $ML_RG_NAME --query "{ip:[].ipAddress}" -o json | jq -r ".ip | @csv")
VM_PUBLIC_IP_PARSED=$(echo $VM_PUBLIC_IP | sed 's/"//g')
PROCESS_NSG_FOR_VM="true"


echo "Init: $VM_PUBLIC_IP_PARSED"

while :
do
  if [ -z "$VM_PUBLIC_IP_PARSED" ]
  then
      echo "$VM_PUBLIC_IP_PARSED is empty..."
  else
      echo "Loop: $VM_PUBLIC_IP_PARSED"
      echo "VM service external IP is $VM_PUBLIC_IP_PARSED"  
      printf '%dh:%dm:%ds\n' $(($TIME/3600)) $(($TIME%3600/60)) $(($TIME%60))
  
      echo "Process NSG: $PROCESS_NSG_FOR_VM"  
   
      ## Just Update VM NSG once=
      if [ $PROCESS_NSG_FOR_VM == "true" ]
      then  
        ## Allow SSH from my Home
        echo "Update VM NSG to allow SSH"
        az network nsg rule create \
          --nsg-name $VM_NSG_NAME \
          --resource-group $ML_RG_NAME \
          --name ssh_allow \
          --priority 100 \
          --source-address-prefixes $MY_HOME_PUBLIC_IP \
          --source-port-ranges '*' \
          --destination-address-prefixes $VM_PRIV_IP \
          --destination-port-ranges 22 \
          --access Allow \
          --protocol Tcp \
          --description "Allow from MY ISP IP"
      fi
    

      echo "Process NSG: $PROCESS_NSG_FOR_VM"   
      ## Just update NG once
      PROCESS_NSG_FOR_VM="false"
      echo "Process NSG: $PROCESS_NSG_FOR_VM"  
 
      ## Checking SSH connectivity
      echo "Testing SSH Conn..."
      
      echo "Enter 2nd Loop..." 
      #while :
      #do 
      #  nc -w 5 -z $VM_PUBLIC_IP_PARSED 22 && break 
      #  echo 'Waiting for remote sshd...' 
      #done

      while :
      do
        if [ "$(ssh -i "$SSH_PRIV_KEY" -o 'StrictHostKeyChecking no' -o "BatchMode=yes" -o "ConnectTimeout 5" $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED  echo up 2>&1)" == "up" ];
        then
          echo "Can connect to $VM_PUBLIC_IP_PARSED, continue"
          break
        else
          echo "Keep trying...."
        fi
      done
      
      echo "Exist 1srt While loop...."
      break
  fi

  countdown "00:00:45"

  VM_PUBLIC_IP=$(az network public-ip list -g $ML_RG_NAME --query "{ip:[].ipAddress}" -o json | jq -r ".ip | @csv")
  VM_PUBLIC_IP_PARSED=$(echo $VM_PUBLIC_IP | sed 's/"//g')

done

## Input Key Fingerprint
echo "Input Key Fingerprint" 
#ssh-keyscan -H $VM_PUBLIC_IP_PARSED >> ~/.ssh/known_hosts
ssh-keygen -F $VM_PUBLIC_IP_PARSED >/dev/null | ssh-keyscan -H $VM_PUBLIC_IP_PARSED >> ~/.ssh/known_hosts

## Copy to VM AKS SSH Priv Key
echo "Copy to VM priv Key of AKS Cluster"
scp  -o 'StrictHostKeyChecking no' -i $SSH_PRIV_KEY $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED:/home/$GENERIC_ADMIN_USERNAME/id_rsa

## Set Correct Permissions on Priv Key
echo "Set good Permissions on AKS Priv Key"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED "chmod 700 /home/$GENERIC_ADMIN_USERNAME/id_rsa"

## Get Credentials
echo "Getting Cluster Credentials"
#AKS_ML_CLUSTER_NAME_FINAL=$(az aks list -g $ML_RG_NAME -o json | jq -r ".[].name")
AKS_ML_CLUSTER_NAME_FINAL=$(az aks list -o table | grep $ML_RG_NAME | awk '{print $1}')
echo "Cluster Name is $AKS_ML_CLUSTER_NAME_FINAL"

az aks get-credentials \
  --resource-group $ML_RG_NAME \
  --name $AKS_ML_CLUSTER_NAME_FINAL \
  --overwrite-existing \
  --debug

echo "Public IP of the VM"
echo $VM_PUBLIC_IP_PARSED

## Create the SSH into Node Helper file
echo "Process SSH into Node into SSH VM"
AKS_1ST_NODE_IP=$(kubectl get nodes -o=wide | awk 'FNR == 2 {print $6}')
AKS_STRING_TO_DO_SSH='ssh -o ServerAliveInterval=180 -o ServerAliveCountMax=2 -i id_rsa'
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED echo "$AKS_STRING_TO_DO_SSH $GENERIC_ADMIN_USERNAME@$AKS_1ST_NODE_IP >> gtno.sh"


