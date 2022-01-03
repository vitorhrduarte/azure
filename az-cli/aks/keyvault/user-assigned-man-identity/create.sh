##!/usr/bin/env bash
set -e
. .././params.sh

## Get AKS Identity and User IT 
echo "Get AKS Identity and User IT"
AKS_SYS_MAN_IDENTITY=$(az aks show \
  --resource-group $AKS_RG \
  --name $AKS_NAME \
  --query identityProfile.kubeletidentity.clientId \
  --output tsv)



## Create a new Manages Identity and use it
#echo "Create a new Manages Identity and use it"
#az identity create \
#  --resource-group <resource-group> \
#  --name <identity-name>

## Assign VMSS identity
#echo "Assign VMSS identity"
#az vmss identity assign \
#  --resource-group <resource-group> \
#  --name <agent-pool-vmss> \
#  --identities <identity-resource-id>

## Assign VMAS Identity
#echo "Assign VMAS Identity"
#az vm identity assign \
#  --resource-group <resource-group> \
#  --name <agent-pool-vm> \
#  --identities <identity-resource-id>





## set policy to access keys in your key vault
echo "set policy to access keys in your key vault"
az keyvault set-policy \
  --name $KVAULT_NAME \
  --key-permissions get \
  --spn $AKS_SYS_MAN_IDENTITY

## set policy to access secrets in your key vault
echo "set policy to access secrets in your key vault"
az keyvault set-policy \
  --name $KVAULT_NAME \
  --secret-permissions get \
  --spn $AKS_SYS_MAN_IDENTITY

## set policy to access certs in your key vault
echo "set policy to access certs in your key vault"
az keyvault set-policy \
  --name $KVAULT_NAME \
  --certificate-permissions get \
  --spn $AKS_SYS_MAN_IDENTITY


## Delete existing yaml file for Secret Provider Class
echo "Delete existing yaml file for Secret Provider Class"
rm -rf secretproviderclass.yaml


## This is a SecretProviderClass example using user-assigned identity to access your key vault
echo "Setting up the yaml for Secret Provider Class"
printf "
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kvname-user-msi
spec:
  provider: azure
  parameters:
    usePodIdentity: \"false\"
    useVMManagedIdentity: \"true\"                    # Set to true for using managed identity
    userAssignedIdentityID: $AKS_SYS_MAN_IDENTITY   # Set the clientID of the user-assigned managed identity to use
    keyvaultName: $KVAULT_NAME                      # Set to the name of your key vault
    cloudName: \"\"                                   # [OPTIONAL for Azure] if not provided, the Azure environment defaults to AzurePublicCloud
    objects:  |
      array:
        - |
          objectName: $KVAULT_NAME
          objectType: secret              # object types: secret, key, or cert
          objectVersion: \"\"               # [OPTIONAL] object versions, default to latest if empty
        #- |
        #  objectName: key1
        #  objectType: key
        #  objectVersion: ""
    tenantId: $TENANTID                   # The tenant ID of the key vault
" >> secretproviderclass.yaml

## Apply SPClass
echo "Apply SPClass"
kubectl apply -f secretproviderclass.yaml

## Create POD
echo "Create POD"
kubectl apply -f pod.yaml

## Sleep 30s
echo "Sleep 30s"
sleep 30

## show secrets held in secrets-store
kubectl exec busybox-secrets-store-inline-user-msi -- ls /mnt/secrets-store/
 
## print a test secret held in secrets-store
kubectl exec busybox-secrets-store-inline-user-msi -- cat /mnt/secrets-store/$KVAULT_NAME
