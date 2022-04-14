##!/usr/bin/env bash


showHelp() {
cat << EOF  
Usage: 

bash create.sh --help/-h  [for help]
bash create.sh -o/--operation <enable disable status> -g/--group <aks-rg-name> -n/--name <aks-name>

Install Pre-requisites JQ

-h, -help,          --help                  Display help

-o, -operation,     --operation             Set operation type for the AKS Http Routing
                                            enable or disable Or status

-g, -group,         --group                 AKS RG Name

-n, -name,          --name                  AKS Name

EOF
}

options=$(getopt -l "help::,operation:,group:,name:" -o "h::o:g:n:" -a -- "$@")

eval set -- "$options"

while true
do
case $1 in
-h|--help) 
    showHelp
    exit 0
    ;;  
-o|--operation)
    shift
    HTTP_ROUTING_OPERATION_TYPE=$1
    ;;  
-g|--group)
    shift
    AKS_RG_NAME=$1
    ;;  
-n|--name)
    shift
    AKS_NAME=$1
    ;;  
--)
    shift
    break
    exit 0    
    ;;  
esac
shift
done


funcHttpRoutingStatus () {
  ## Get the current AKS Http Routing Status
  echo "Get the current AKS Http Routing Status"

  AKS_HR_STATUS=$(az aks show \
    --resource-group $AKS_RG_NAME \
    --name $AKS_NAME \
    --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName \
    --output table)
}



funcHttpRoutingAdd () {
  ## Add Http Routing Add-On
  echo "Add Http Routing Add-On"
  az aks enable-addons \
    --resource-group $AKS_RG_NAME \
    --name $AKS_NAME \
    --addons http_application_routing \
    --debug
}



funcHttpRoutingRemove () {
  ## Remove Http Routing Add-On
  echo "Remove Http Routing Add-On"
  az aks disable-addons \
    --addons http_application_routing \
    --name $AKS_NAME \
    --resource-group $AKS_RG_NAME \
    --debug

}


funcHttpRoutingSampleApp () {


}


if [[ "$VNET_OPERATION_TYPE" == "status"  ]]
then
   
   echo "Origin Details..."
   funcShowPeerings $JS_VNET_RG $JS_VNET_NAME
   echo ""   
   echo "Destination Details..."
   funcShowPeerings $DEST_VNET_RG $DEST_VNET_NAME
elif [[ "$VNET_OPERATION_TYPE" == "peer"  ]]
then
   funcPeerVnet  
elif [[ "$VNET_OPERATION_TYPE" == "unpeer" ]]
then
   funcUnPeerVnet
else
   echo "Invalid Option..."
   echo "Exiting..."
   exit
fi












