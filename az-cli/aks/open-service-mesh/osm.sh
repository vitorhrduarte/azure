#!/bin/bash
set -e
. ./params.sh


showHelp() {
cat << EOF  
Usage: 

bash osm.sh --help/-h  [for help]
bash osm.sh -s/--scope <aks osm>  -o/--operation <enable disable status> 


Install Pre-requisites jq and dialog

-h, -help,          --help                  Display help

-s, --scope,        --scope                 Runs command in AKS OSM Install/Removal
                                            or in OSM Internal Config/Setup     

-o, -operation,     --operation             Set operation type for the OSM
                                            enable or disable Or status

EOF
}

options=$(getopt -l "help::,scope,operation:" -o "h::s:o:" -a -- "$@")

eval set -- "$options"

while true
do
case $1 in
-h|--help) 
    showHelp
    exit 0
    ;;  
-s|--scope)
    shift
    OSM_SCOPE_TYPE=$1
    ;;  
-o|--operation)
    shift
    OSM_OPERATION_TYPE=$1
    ;;
--)
    shift
    break
    exit 0    
    ;;  
esac
shift
done


if [[ "$OSM_SCOPE_TYPE"  == "aks" ]]
then
    if [[ "$OSM_OPERATION_TYPE" == "status" ]]
    then
    	echo "Selected option: $OSM_OPERATION_TYPE in Scope: $OSM_SCOPE_TYPE"
    	echo ""
        
        IS_OSM_ENABLE=$(az aks addon list \
          --name $AKS_NAME \
          --resource-group $AKS_RG_NAME \
          --output json | jq -r '.[] | select( .name == "open-service-mesh" ) | [ .enabled ] | @tsv')
        
        echo "Is AKS OSM enabled in Cluster $AKS_NAME : $IS_OSM_ENABLE"

	elif [[ "$OSM_OPERATION_TYPE" == "enable" ]]
	then
		echo "Selected option: $OSM_OPERATION_TYPE in Scope: $OSM_SCOPE_TYPE"
        echo ""
        echo "Deploy OSM Add-on in AKS Cluster"
        
        bash support-code/deploy.sh

	elif [[ "$OSM_OPERATION_TYPE" == "disable" ]]
	then
		echo "Selected option: $OSM_OPERATION_TYPE in Scope: $OSM_SCOPE_TYPE"
        echo ""
        echo "Removing OSM Add-on in AKS Cluster"		

        bash support-code/remove.sh

	else
    	echo "Invalid Option"
    	echo "Exiting..."  
	fi
elif [[ "$OSM_SCOPE_TYPE"  == "osm" ]]
then
    if [[ "$OSM_OPERATION_TYPE" == "status" ]]
	then
    	echo "Selected option: " $OSM_OPERATION_TYPE
		echo ""
    	echo "Status OSM Setup/Config of Permissive Mode..."

        kubectl get meshconfig osm-mesh-config -n kube-system -o=jsonpath='{$.spec.traffic.enablePermissiveTrafficPolicyMode}' 

	elif [[ "$OSM_OPERATION_TYPE"  == "enable"  ]]
	then
    	echo "Selected option: " $OSM_OPERATION_TYPE
		echo ""
    	echo "Disabling OSM Permissive Mode"
    
        kubectl patch meshconfig osm-mesh-config -n kube-system -p '{"spec":{"traffic":{"enablePermissiveTrafficPolicyMode":false}}}' --type=merge

	elif [[ "$OSM_OPERATION_TYPE"  == "disable"  ]]
    then
        echo "Selected option: " $OSM_OPERATION_TYPE
		echo ""
        echo "Enabling OSM Permissive Mode"

        kubectl patch meshconfig osm-mesh-config -n kube-system -p '{"spec":{"traffic":{"enablePermissiveTrafficPolicyMode":true}}}' --type=merge

    else
    	echo "Invalid Option"
    	echo "Exiting..."  
	fi
else
	echo "Invalid Option"
	echo "Exiting..."  
fi
