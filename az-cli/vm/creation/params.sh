## Create Only JS Server
COJSS="0"
## Create Only K8S SErver
COK8SS="1"
## Generic VMS RG
VMS_PURPOSE="k8s01"
VMS_CORE_RG_NAME="rg-vms-"$VMS_PURPOSE
VMS_CORE_RG_LOCATION="westeurope"

## Linux Jump Server
LINUX_JS_RG_LOCATION=$VMS_CORE_RG_LOCATION
LINUX_JS_AUTH_TYPE="ssh"
LINUX_JS_NAME="sshclient-"$VMS_PURPOSE
LINUX_JS_INTERNAL_NAME="sshclient-"$VMS_PURPOSE
LINUX_JS_IMAGE_PROVIDER="Canonical"
LINUX_JS_IMAGE_OFFER="UbuntuServer"
LINUX_JS_IMAGE_SKU="18.04-LTS"
LINUX_JS_IMAGE_VERSION="latest"
LINUX_JS_IMAGE="$LINUX_JS_IMAGE_PROVIDER:$LINUX_JS_IMAGE_OFFER:$LINUX_JS_IMAGE_SKU:$LINUX_JS_IMAGE_VERSION"
LINUX_JS_PUBLIC_IP="" 
LINUX_JS_SIZE="Standard_D2s_v3"
LINUX_JS_STORAGE_SKU="Standard_LRS"
LINUX_JS_OS_DISK_SIZE="40"
LINUX_JS_OS_DISK_NAME="$LINUX_JS_NAME""_disk_01"
LINUX_JS_NSG_NAME="$LINUX_JS_NAME""_nsg"
LINUX_JS_NIC_NAME="$LINUX_JS_NAME""nic01"
LINUX_JS_TAGS="env=kubernetes"
LINUX_JS_PUBLIC_IP_NAME="sshclientpublicip"
LINUX_JS_DEFAULT_IP_CONFIG="ipconfig1"

## Windows Jump Server
WINDOWS_JS_RG_LOCATION=$VMS_CORE_RG_LOCATION
WINDOWS_JS_NAME="rdcclient-"$VMS_PURPOSE
WINDOWS_JS_INTERNAL_NAME="rdcclient-"$VMS_PURPOSE
WINDOWS_JS_IMAGE_PROVIDER="MicrosoftWindowsServer"
WINDOWS_JS_IMAGE_OFFER="WindowsServer"
WINDOWS_JS_IMAGE_SKU="2019-Datacenter"
WINDOWS_JS_IMAGE_VERSION="latest"
WINDOWS_JS_IMAGE="$WINDOWS_JS_IMAGE_PROVIDER:$WINDOWS_JS_IMAGE_OFFER:$WINDOWS_JS_IMAGE_SKU:$WINDOWS_JS_IMAGE_VERSION"
WINDOWS_JS_PUBLIC_IP=""
WINDOWS_JS_SIZE="Standard_D4s_v3"
WINDOWS_JS_STORAGE_SKU="Standard_LRS"
WINDOWS_JS_OS_DISK_SIZE="130"
WINDOWS_JS_OS_DISK_NAME="$WINDOWS_JS_NAME""_disk_01"
WINDOWS_JS_NSG_NAME="$WINDOWS_JS_NAME""_nsg"
WINDOWS_JS_NIC_NAME="$WINDOWS_JS_NAME""nic01"
WINDOWS_JS_TAGS="env=kubernetes"
WINDOWS_JS_PUBLIC_IP_NAME="rdcclientpublicip"
WINDOWS_JS_DEFAULT_IP_CONFIG="ipconfig1"

## Networking Jump Servers
## Core 
VMS_CORE_VNET_RG=$VMS_CORE_RG_NAME
VMS_CORE_VNET_NAME="core-vms"
VMS_CORE_VNET_CIDR="10.0.0.0/16"
## Linux
VMS_JS_LINUX_SNET_NAME="js-linux"
VMS_JS_LINUX_SNET_CIDR="10.0.32.0/29"
## Windows
VMS_JS_WIN_SNET_NAME="js-windows"
VMS_JS_WIN_SNET_CIDR="10.0.32.8/29"
## K8s Server
VMS_K8S_SNET_NAME="k8s-servers"
VMS_K8S_SNET_CIDR="10.0.0.0/19"
## Security measure
MY_HOME_PUBLIC_IP=$(curl ifconfig.io)


## K8s
K8S_CONTROL_PLANE_NAME="cp01"
K8S_CONTROL_PLANE_OS_DISK_NAME=$K8S_CONTROL_PLANE_NAME"_disk01"

K8S_WORKER_NODES_NAME="wk"
K8S_WORKER_NODES_OS_DISK_NAME="_disk0" 
