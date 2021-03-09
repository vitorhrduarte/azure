##!/usr/bin/env bash
set -e
. ./params.sh

## Create AppGtw RG
echo "Create AppGtw RG"
az group create \
  --name $APPGTW_RG_NAME \
  --location $APPGTW_LOCATION \
  --debug

## Create AppGtw Vnet
echo "Create AppGtw Vnet"
az network vnet create \
  --name $APPGTW_MAIN_VNET_NAME \
  --resource-group $APPGTW_RG_NAME \
  --location $APPGTW_LOCATION \
  --address-prefixes $APPGTW_ADDRESS_PREFIX \
  --subnet-name $APPGTW_SUBNET_NAME \
  --subnet-prefixes $APPGTW_SUBNET_PREFIX \
  --debug

## Create Public IP for AppGtw
echo "Create public IP for AppGtw"
az network public-ip create \
  --resource-group $APPGTW_RG_NAME \
  --name $APPGTW_PUBLIC_IP_NAME \
  --allocation-method $APPGTW_PUBLIC_IP_ALLOCATION_METHOD \
  --sku $APPGTW_PUBLIC_IP_SKU \
  --debug

## Create AppGtw
echo "Deploy AppGtw"
az network application-gateway create \
  -g $APPGTW_RG_NAME \
  -n $APPGTW_NAME \
  --capacity $APPGTW_CAPACITY \
  --sku $APPGTW_SKU \
  --vnet-name $APPGTW_MAIN_VNET_NAME \
  --subnet $APPGTW_SUBNET_NAME \
  --public-ip-address $APPGTW_PUBLIC_IP_NAME \
  --debug

## Create AKS Subnet
echo "Create AKS Subnet"
az network vnet subnet create \
  --name $AKS_SUBNET_NAME \
  --resource-group $AKS_RG_NAME \
  --vnet-name $APPGTW_MAIN_VNET_NAME \
  --address-prefixes $AKS_ADDRESS_PREFIX \
  --debug

### Get the id of the Subnet for AKS
echo "Get the Subnet for AKS ID" 
AKS_SNET_ID=$(az network vnet subnet show -g $AKS_RG_NAME --vnet-name $APPGTW_MAIN_VNET_NAME --name  $AKS_SUBNET_NAME --query id -o tsv)

### create aks cluster
echo "Creating AKS Cluster RG"
az group create \
  --name $AKS_RG_NAME \
  --location $AKS_RG_LOCATION  \
  --tags env=lab > /dev/null 2>&1


echo "Creating AKS Cluster"
az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --service-principal $SP \
  --client-secret $SPPASS \
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
  --debug


### Create RG for VM
### Skip if RG already been Created
echo "Create RG if required"
if [ $(az group list -o table | awk '{print $1}' | grep "^$AKS_RG_NAME" | wc -l) -eq 1 ]; then echo "RG Already there! Continue"; else  az group create --location $AKS_RG_LOCATION --name $AKS_RG_NAME; fi

### VM SSS Client subnet Creation
echo "Create VM SSH Subnet"
az network vnet subnet create \
  -g $AKS_RG_NAME \
  --vnet-name $APPGTW_MAIN_VNET_NAME \
  -n $SSH_VM_SUBNET_NAME \
  --address-prefixes $SSH_VM_SUBNET_CIDR \
  --debug


### VM NSG Create
echo "Create NSG"
az network nsg create \
  -g $AKS_RG_NAME \
  -n $SSH_VM_NSG_NAME \
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
  -g $AKS_RG_NAME \
  --vnet-name $APPGTW_MAIN_VNET_NAME \
  --subnet $SSH_VM_SUBNET_NAME \
  -n $SSH_VM_NIC_NAME \
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
  --vnet-name $APPGTW_MAIN_VNET_NAME \
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
#echo $SSH_VM_PUBLIC_IP_PARSED


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

echo "Sleeping for 15s"
sleep 15

## Create a namespace for your ingress resources
echo "Creating NS for IngController"
kubectl create namespace ingress-basic

## Add the ingress-nginx repository
echo "Add IngController Helm Repo"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

## Use Helm to deploy an NGINX ingress controller
echo "Deploy IngController"
helm install nginx-ingress ingress-nginx/ingress-nginx \
    --namespace ingress-basic \
    -f internal-ingress.yaml \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.admissionWebhooks.patch.nodeSelector."beta\.kubernetes\.io/os"=linux

echo "Sleep for 45s"
sleep 45

echo "Deploy AKS-Helloword ONE"
kubectl apply -f aks-helloworld-one.yaml --namespace ingress-basic

echo "Deploy AKS-Helloword TWO"
kubectl apply -f aks-helloworld-two.yaml --namespace ingress-basic

echo "Deploy App Ingress Controller"
kubectl apply -f hello-world-ingress.yaml --namespace ingress-basic

echo "Wait 100s for AKS to assign IP"
sleep 100

echo "Get the Ingress IP"
INGRESS_INTERNAL_IP=$(kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-basic -o json | jq ".status.loadBalancer.ingress[].ip" | sed 's/"//g')
echo $INGRESS_INTERNAL_IP

echo "Get AppGtw Backend information"
APPGTW_POOL_NAME=$(az network application-gateway address-pool list --resource-group $APPGTW_RG_NAME --gateway $APPGTW_NAME  -o json | jq ".[].name" | sed 's/"//g')

echo "Add in AppGtw the Backend IP"
az network application-gateway address-pool update \
  --resource-group $APPGTW_RG_NAME  \
  --gateway $APPGTW_NAME \
  --name $APPGTW_POOL_NAME \
  --servers $INGRESS_INTERNAL_IP \
  --debug

echo "Add probe to the Ingress Controller IP"
az network application-gateway probe create \
  --gateway-name $APPGTW_NAME \
  --name app-probe \
  --path "/" \
  --protocol Http \
  --resource-group $APPGTW_RG_NAME \
  --host $INGRESS_INTERNAL_IP \
  --debug

echo "Public IP of the VM"
echo $SSH_VM_PUBLIC_IP_PARSED
