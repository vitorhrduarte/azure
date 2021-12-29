##!/usr/bin/env bash
set -e
. ./params.sh

## Enable AKS add-on for Azure Key Vault - KV
echo "Enable AKS add-on for Azure Key Vault - KV"
az aks enable-addons \
  --addons azure-keyvault-secrets-provider \
  --name $AKS_NAME \
  --resource-group $AKS_RG \
  --debug

## Double check if KV provider for Secret Store CSI driver is OK
echo "Double check if KV provider for Secret Store CSI driver is OK"
kubectl get pods --namespace kube-system -l 'app in (secrets-store-csi-driver, secrets-store-provider-azure)'

## KV RG Creation
echo "KV RG Creation"
az group create \
  --name $KVAULT_RG \
  --location $KVAULT_LOCATION \

## Create KV
echo "Create KV"
az keyvault create \
  --name $KVAULT_NAME \
  --resource-group $KVAULT_RG \
  --location $KVAULT_LOCATION \
  --debug

## Create KV Secret Sample
echo "Create KV Secret Sample"
az keyvault secret set \
  --vault-name $KVAULT_NAME \
  --name $KVAULT_SECRET_NAME \
  --value $KVAULT_SECRET_VALUE \
  --debug

