## Apply VM Update and personalization packages
JS_UPDATE="1"
JS_USE_JIT="1"

## Core Networking
JS_MAIN_VNET_RG="rg-vm-jpsrv"
JS_MAIN_VNET_NAME="vnet-vm-jpsrv"
JS_MAIN_VNET_LOCATION="westeurope"
JS_MAIN_VNET_CIDR="10.0.0.0/24"
JS_SUBNET_CIDR="10.0.0.0/27"
JS_SUBNET_NAME="snet-vm-jpsrv"
JS_PRIV_IP="10.0.0.4/32"
JS_MY_ISP_IP=$(curl ifconfig.io)

## Public IP Name
JS_PUBLIC_IP_NAME="ljspip" 
JS_DEFAULT_IP_CONFIG="ipconfig1"

## VM SSH Client
JS_RG_LOCATION=$JS_VNET_LOCATION
JS_AUTH_TYPE="ssh"
JS_NAME="ljs"
JS_INTERNAL_NAME="ljs"
JS_IMAGE_PROVIDER="Canonical"
JS_IMAGE_OFFER="0001-com-ubuntu-server-focal"
JS_IMAGE_SKU="20_04-lts-gen2"
JS_IMAGE_VERSION="latest"
JS_IMAGE="$JS_IMAGE_PROVIDER:$JS_IMAGE_OFFER:$JS_IMAGE_SKU:$JS_IMAGE_VERSION"
JS_PUBLIC_IP="" 
JS_SIZE="Standard_D2as_v4"
JS_STORAGE_SKU="Standard_LRS"
JS_OS_DISK_SIZE="90"
JS_OS_DISK_NAME="$JS_NAME""_disk_01"
JS_NSG_NAME="$JS_NAME""_nsg"
JS_NIC_NAME="$JS_NAME""nic01"
JS_TAGS="purpose=jumpsrv os=linux"
