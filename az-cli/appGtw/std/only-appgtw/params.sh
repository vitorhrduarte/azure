## AppGtw Settings
APPGTW_RG_NAME="rg-aks-agic"                    ## Existing AKS RG name
APPGTW_LOCATION="westeurope"                    ## Existing AKS Location 

## AppGtw Vnet
APPGTW_MAIN_VNET_NAME="vnet-aks-agic"           ## Existing Main Vnet
APPGTW_ADDRESS_PREFIX="10.5.0.0/16"             ## Existing Main Vnet Cidr
APPGTW_SUBNET_NAME="snet-appgtw"
APPGTW_SUBNET_PREFIX="10.5.10.0/24"

## Deploy AppGtw
APPGTW_NAME="evangelionappgtw"
APPGTW_CAPACITY="2"
APPGTW_SKU="Standard_v2"

## AppGtw Public IP
APPGTW_PUBLIC_IP_NAME="evaPublicIP"
APPGTW_PUBLIC_IP_ALLOCATION_METHOD="Static"
APPGTW_PUBLIC_IP_SKU="Standard"


