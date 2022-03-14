##!/usr/bin/env bash
set -e
. ./params.sh

## Function to get Peerings status
funcShowPeerings () {
  az network vnet peering list \
    --resource-group $1 \
    --vnet-name $2 \
    --output json | jq -r ".[] | [ .name, .peeringState, .resourceGroup, .remoteVirtualNetworkAddressSpace.addressPrefixes[], .peeringSyncLevel , .remoteVirtualNetwork.resourceGroup] | @tsv" | column -t
}


## Function to UnPeer Vnet's
funcUnPeerVnet () {

  ## Get Vnet's ID's
  echo "Getting Vnet's ID's"
  ORIGIN_JS_VNET_ID=$(az network vnet list -o json | jq -r ".[] | select( .name == \"$JS_VNET_NAME\" ) | [ .id ] | @tsv" | column -t)
  echo "$JS_VNET_NAME ID: $ORIGIN_JS_VNET_ID"
  DESTINATION_VNET_ID=$(az network vnet list -o json | jq -r ".[] | select( .name == \"$DEST_VNET_NAME\" ) | [ .id ] | @tsv" | column -t)
  echo "$DEST_VNET_NAME ID: $DESTINATION_VNET_ID"
  
  ## Peering Vnets
  echo "Peering $JS_VNET_NAME-To-$DEST_VNET_NAME"
  az network vnet peering delete \
    --name "$JS_VNET_NAME-To-$DEST_VNET_NAME" \
    --resource-group $JS_VNET_RG \
    --vnet-name $JS_VNET_NAME \
    --debug
  
  echo "Peering $DEST_VNET_NAME-To-$JS_VNET_NAME"
  az network vnet peering delete \
    --name  "$DEST_VNET_NAME-To-$JS_VNET_NAME" \
    --resource-group $DEST_VNET_RG \
    --vnet-name $DEST_VNET_NAME \
  --debug

}


## Function to Peer Vnet's
funcPeerVnet () {

  ## Get Vnet's ID's
  echo "Getting Vnet's ID's"
  ORIGIN_JS_VNET_ID=$(az network vnet list -o json | jq -r ".[] | select( .name == \"$JS_VNET_NAME\" ) | [ .id ] | @tsv" | column -t)
  echo "$JS_VNET_NAME ID: $ORIGIN_JS_VNET_ID"
  DESTINATION_VNET_ID=$(az network vnet list -o json | jq -r ".[] | select( .name == \"$DEST_VNET_NAME\" ) | [ .id ] | @tsv" | column -t)
  echo "$DEST_VNET_NAME ID: $DESTINATION_VNET_ID"
  
  ## Peering Vnets
  echo "Peering $JS_VNET_NAME-To-$DEST_VNET_NAME"
  az network vnet peering create \
    --name "$JS_VNET_NAME-To-$DEST_VNET_NAME" \
    --resource-group $JS_VNET_RG \
    --vnet-name $JS_VNET_NAME \
    --remote-vnet $DESTINATION_VNET_ID \
    --allow-vnet-access \
    --debug
  
  echo "Peering $DEST_VNET_NAME-To-$JS_VNET_NAME"
  az network vnet peering create \
    --name  "$DEST_VNET_NAME-To-$JS_VNET_NAME" \
    --resource-group $DEST_VNET_RG \
    --vnet-name $DEST_VNET_NAME \
    --remote-vnet $ORIGIN_JS_VNET_ID \
    --allow-vnet-access \
    --debug

}




showHelp() {
cat << EOF  
Usage: 

bash create.sh --help/-h  [for help]
bash create.sh -o/--operation <peer unpeer status>

Install Pre-requisites jq and dialog

-h, -help,          --help                  Display help

-o, -operation,     --operation             Set operation type for the VNET Peering
                                            peer or unpeer Or status

EOF
}

options=$(getopt -l "help::,operation:" -o "h::o:" -a -- "$@")

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
    VNET_OPERATION_TYPE=$1
    ;;  
--)
    shift
    break
    exit 0    
    ;;  
esac
shift
done



if [[ "$VNET_OPERATION_TYPE" == "status"  ]]
then
   funcShowPeerings $JS_VNET_RG $JS_VNET_NAME
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












