## AKS Settings
AKS_NAME="aks-kvault"
AKS_RG="rg-"$AKS_NAME

## Key Vault Setting
KVAULT_NAME="kv-m1aolkv"
KVAULT_RG="rg-"$KVAULT_NAME
KVAULT_LOCATION="northeurope"

## Key Vault
## Your Azure key vault can store keys, secrets, and certificates. 
## In this example, you'll set a plain-text secret called
## Key Vault must be unique
KVAULT_SECRET_NAME=$KVAULT_NAME
KVAULT_SECRET_VALUE="blablabla"

