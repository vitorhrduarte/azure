## Jump VM Generic Setup
JS_USE_JIT="1"
JS_HAS_NSG="1"

## Core Networking
JS_MAIN_VNET_RG="rg-vm-jpsrv"
JS_MAIN_VNET_NAME="vnet-vm-jpsrv"
JS_MAIN_VNET_LOCATION="westeurope"
JS_MAIN_VNET_CIDR="10.0.0.0/24"
JS_SUBNET_CIDR="10.0.0.32/27"
JS_SUBNET_NAME="snet-vm-winjpsrv"
JS_SUBNET_PRIV_IP="10.0.0.33/32"

## Public IP Name
JS_PUBLIC_IP_NAME="jswinpip"
JS_DEFAULT_IP_CONFIG="ipconfig1"


## Windows VM Details
JS_RG_LOCATION=$JS_VNET_LOCATION
JS_AUTH_TYPE="password"
JS_NAME="wjs"
JS_INTERNAL_NAME="wjs"
JS_IMAGE_PROVIDER="MicrosoftWindowsDesktop"
JS_IMAGE_OFFER="Windows-10"
JS_IMAGE_SKU="20h2-pro-g2"
JS_IMAGE_VERSION="latest"
JS_IMAGE="$JS_IMAGE_PROVIDER:$JS_IMAGE_OFFER:$JS_IMAGE_SKU:$JS_IMAGE_VERSION"
JS_PUBLIC_IP="" 
JS_SIZE="Standard_D4s_v3"
JS_STORAGE_SKU="Premium_LRS" # Standard_LRS
JS_OS_DISK_SIZE="130"
JS_OS_DISK_NAME="$JS_NAME""_disk_01"
JS_NSG_NAME="$JS_NAME""_nsg"
JS_NIC_NAME="$JS_NAME""nic01"
JS_TAGS="purpose=jumpsrv os=windows"


