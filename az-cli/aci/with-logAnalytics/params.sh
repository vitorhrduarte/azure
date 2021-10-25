## Log Analytics Specs
LOG_PURPOSE="lab"
LOG_RG_NAME="rg-lawks-"$LOG_PURPOSE
LOG_RG_LOCATION="westeurope"
LOG_WKS_NAME="lawks-"$LOG_PURPOSE
LOG_SKU="PerGB2018"

## ACI Settings
ACI_CONTAINER_NAME_01="aci-welcome"
ACI_CONTAINER_IMAGE_01="mcr.microsoft.com/azuredocs/aci-helloworld"
ACI_CONTAINER_NAME_02="aci-fluentd"
ACI_CONTAINER_IMAGE_02="fluent/fluentd"
ACI_CONTAINER_LISTENING_PORT_01="80"

## ACI Random String Generator
ACI_LENGTH_STRING=12
ACI_CONTAINER_DNS_LABEL_01=$(tr -dc a-z </dev/urandom | head -c $ACI_LENGTH_STRING)
ACI_CONTAINER_DNS_LABEL_02=$(tr -dc a-z </dev/urandom | head -c $ACI_LENGTH_STRING)
