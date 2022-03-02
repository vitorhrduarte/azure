## ACI Details
ACI_GRP_NAME="appgrp02"
ACI_GRP_IMAGE="mcr.microsoft.com/azuredocs/aci-helloworld"
ACI_EXPOSE_PORT="80"
ACI_USE_PROTOCOL="TCP"
ACI_CPU_REQUEST="1.0"
ACI_MEM_REQUEST="1.5"
ACI_IP_TYPE="Private"

## ACI YAML File
ACI_YAML_FILE_NAME="aci-deploy.yaml"

## ACI Vnet Settings
ACI_MAIN_VNET_RG="rg-aci-core"
ACI_MAIN_VNET_NAME="vnet-aci-core"
ACI_MAIN_VNET_LOCATION="westeurope"
ACI_MAIN_VNET_CIDR="10.100.0.0/16"
ACI_SUBNET_CIDR="10.100.2.0/24"
ACI_SUBNET_NAME="snet-aci-grp02"
