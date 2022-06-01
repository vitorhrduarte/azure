## App Gateway Settings
APPGTW_ID=""
APPGTW_NAME="eagles"              ## Mandatory
APPGTW_SNET_CIDR=""               ## Mandatory
APPGTW_SNET_ID=""
APPGTW_WATCH_NAMESPACE=""

## AKS Settings
AKS_NAME="aks-agic"
AKS_RG_NAME="rg-$AKS_NAME"

## Auth
AUTH_TYPE="aad"                    ## SP(sp) or AAD(aad) Pod Identity

## Auth Type AAD
AUTH_AAD_ID_NAME="agicaadpod"
AUTH_ADD_RG_NAME=$AKS_RG_NAME


## Auth Type SP
AUTH_SP_NAME="agicsp"


