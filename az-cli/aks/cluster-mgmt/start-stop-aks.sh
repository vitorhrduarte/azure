#!/bin/bash


showHelp() {
cat << EOF  
Usage: 

bash start-stop-aks.sh --help/-h  [for help]
bash start-stop-aks.sh -o/--operation <start stop status> -s/--scope <all one>

Install Pre-requisites jq and dialog

-h, -help,          --help                  Display help

-o, -operation,     --operation             Set operation type for the AKS cluster
                                            Start Or Stop Or Status

-s, -scope,         --scope                 Apply previous operation to All or One Cluster			

EOF
}

options=$(getopt -l "help::,operation:,scope:" -o "h::o:s:" -a -- "$@")

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
    AKS_OPERATION_TYPE=$1
    ;;  
-s|--scope)
    shift
    AKS_OPERATION_SCOPE=$1
    ;;
--)
    shift
    break
    exit 0    
    ;;  
esac
shift
done



OPER_TYPE=(start stop status)
OPER_SCOPE=(all one)

FIRST_MATCH=0
SECOND_MATCH=0
for oper in "${OPER_TYPE[@]}"; do
    if [[ $oper = "$AKS_OPERATION_TYPE" ]]; then
        FIRST_MATCH=1
        echo "Operation Found... continue..."

		for scpe in "${OPER_SCOPE[@]}"; do
    		if [[ $scpe = "$AKS_OPERATION_SCOPE" ]]; then
        		SECOND_MATCH=1
                echo "Scope Found... continue..."
        		break
    		fi  
		done
		if [[ $SECOND_MATCH = 0 ]]; then
    		echo "No match found"
    		echo "Exit script..."
    		exit
		fi

        break
    fi
done
if [[ $FISRT_MATCH = 0 ]]; then
    echo "No match found"
    echo "Exit script..."
    exit
fi

if [[ "$AKS_OPERATION_SCOPE" == "all" ]] && [[ "$AKS_OPERATION_TYPE" != "status" ]]; then
  ## Get AKS
  echo "Execute $AKS_OPERATION_SCOPE in All AKS cluster"
  AKS_ARRAY=($(az aks list \
      --output json | jq -r ".[] | [ .name, .resourceGroup ] | @csv"))

  for akscl in "${AKS_ARRAY[@]}"; do
    AKS_CL_ARRAY=($(echo $akscl | tr -d '"' |tr "," "\n"))
    
    ## Execute Operation
    echo "$AKS_OPERATION_TYPE cluster ${AKS_CL_ARRAY[0]}"
    az aks $AKS_OPERATION_TYPE --name ${AKS_CL_ARRAY[0]} --resource-group ${AKS_CL_ARRAY[1]} --debug
  done  

elif [[ "$AKS_OPERATION_TYPE" == "status" ]]; then
  ## Get AKS cluster Status
  echo "Show status of AKS clusters"  

  AKS_ARRAY=($(az aks list \
     --output json | jq -r ".[] | [ .name, .resourceGroup ] | @csv"))
  
  for akscl in "${AKS_ARRAY[@]}"; do
     AKS_CL_ARRAY=($(echo $akscl | tr -d '"' |tr "," "\n"))
  
     ## Execute Show Status
     AKS_STATUS=$(az aks show --name ${AKS_CL_ARRAY[0]} --resource-group ${AKS_CL_ARRAY[1]} -o json | jq -r '.powerState.code')
     echo "AKS Cluster ${AKS_CL_ARRAY[0]} in RG: ${AKS_CL_ARRAY[1]} is: " $AKS_STATUS
  done

elif [[ "$AKS_OPERATION_SCOPE" == "one" ]]; then
  ## Get AKS
  AKS_ARRAY=($(az aks list \
    --output json | jq -r ".[] | [ .name, .resourceGroup ] | @csv"))

  ## Declare AKS Options List/Array
  declare -a AKS_OPTIONS

  ## Show Array options
  for i in ${!AKS_ARRAY[@]}
  do
    AKS_OPTIONS+=(${AKS_ARRAY[$i]} $i)
  done

  ## Define GUI Window - AKS
  HEIGHT=30
  WIDTH=100
  CHOICE_HEIGHT=10
  BACKTITLE="AKS Details"
  TITLE="Choose AKS"
  MENU="Choose one of the following options:"

  ## Define User Choice
  AKS_CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${AKS_OPTIONS[@]}" \
                2>&1 >/dev/tty)

  ## Parsing Choice
  TMP_AKS_CHOICE=${AKS_CHOICE[0]}
  TMP_AKS_CHOICE_ARRAY=($(echo $TMP_AKS_CHOICE | tr -d '"' |tr "," "\n"))

  ## Execute Operation
  echo "$AKS_OPERATION_TYPE cluster ${TMP_AKS_CHOICE_ARRAY[0]}"
  az aks $AKS_OPERATION_TYPE --name ${TMP_AKS_CHOICE_ARRAY[0]} --resource-group ${TMP_AKS_CHOICE_ARRAY[1]} --debug

fi



