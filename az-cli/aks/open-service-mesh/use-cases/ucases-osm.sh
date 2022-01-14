##!/usr/bin/env bash
set -e
. ../params.sh

copyParams() {
  cp ../params.sh .  
}

deleteParams() {
  rm -rf params.sh
}


showHelp() {
cat << EOF  
Usage: 

bash osm.sh --help/-h  [for help]
bash osm.sh -s/--scope <split access >  -o/--operation <deploy remove> 


Install Pre-requisites jq and dialog

-h, -help,          --help                  Display help

-s, --scope,        --scope                 Apply Use-Case Scenario for Splitting Traffic
                                            Or Access APP
                                                 

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


if [[ "$OSM_SCOPE_TYPE"  == "access" ]]
then
    if [[ "$OSM_OPERATION_TYPE" == "deploy" ]]
    then
        echo "Selected option: $OSM_OPERATION_TYPE in Scope: $OSM_SCOPE_TYPE"
        echo ""

		## Deploy SMI to access the APP
		echo "Deploy SMI to access the APP"
	    kubectl apply -f define-osm-app-level/allow-bookbuyer-smi.yaml	

    elif [[ "$OSM_OPERATION_TYPE" == "remove" ]]
    then
        echo "Selected option: $OSM_OPERATION_TYPE in Scope: $OSM_SCOPE_TYPE"
        echo ""
		
        ## Remove SMI to access the APP
        echo "Remove SMI to access the APP"
        kubeclt delete -f define-osm-app-level/allow-bookbuyer-smi.yaml
    
    else
        echo "Invalid Option"
        echo "Exiting..."  
    fi
elif [[ "$OSM_SCOPE_TYPE"  == "split" ]]
then
    if [[ "$OSM_OPERATION_TYPE" == "deploy" ]]
    then
        echo "Selected option: " $OSM_OPERATION_TYPE
        echo ""
		
		## Deploy V2 of BookBuyer APP
		echo "Deploy V2 of BookBuyer APP"
		kubectl apply -f traffic-split/bookbuyer-v2.yaml

		## Deploy Traffic Split
		echo "Deploy Traffic Split"
		kubectl apply -f traffic-split/bookbuyer-split-smi.yaml		

    elif [[ "$OSM_OPERATION_TYPE"  == "remove"  ]]
    then
        echo "Selected option: " $OSM_OPERATION_TYPE
        echo ""
        
        ## Removing Traffic Split
        echo "Removing Traffic Split"
        kubectl delete -f traffic-split/bookbuyer-split-smi.yaml
		
        ## Removing V2 of BookBuyer APP
        echo "Removing V2 of BookBuyer APP"
        kubectl delete -f traffic-split/bookbuyer-v2.yaml

    else
        echo "Invalid Option"
        echo "Exiting..."  
    fi
else
    echo "Invalid Option"
    echo "Exiting..."  
fi



