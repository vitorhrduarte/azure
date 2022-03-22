#!/bin/bash


#################################
## Generic Variable - Definition#
#################################

## Jit Details
AZURE_VM_JIT_CREATION_NAME="jit-vm.json"
AZURE_VM_JIT_INITIATE_NAME="jit-vm-post.json"
AZURE_VM_JIT_DURATION="P1D" # 1 DAY, for hours use: PT6H

## Local ISP Details
MY_ISP_IP=$(curl -4 -s https://ifconfig.io)

## Az VM Jit Policy Name
AZ_VM_JIT_POL_NAME="linux"



#############
## Functions#
#############


showHelp() {
cat << EOF  
Usage: 

bash jit.sh --help/-h  [for help]
bash jit.sh -o/--operation <status create delete init> -m/--machine <vm-name> -g/--group <vm-resourceGroup> -p/--port <port-number>

Install Pre-requisites jq and dialog

-h, -help,          --help                  Display help

-o, -operation,     --operation             Set operation type for the JIT actions
                                            Status, create, delete Or initiate (init)

-m, -machine,       --machine               Apply previous operation to All or One Cluster          

-p, -port           --port                  Port to be opened 

-g, -rg,            --rg                    VM Resource Group  

EOF
}

options=$(getopt -l "help::,operation:,machine:,rg:,port:" -o "h::o:m:g:p:" -a -- "$@")

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
    JIT_OPERATION_TYPE=$1
    ;;  
-m|--machine)
    shift
    JIT_OPERATION_VM=$1
    ;;  
-g|--rg)
    shift
    JIT_OPERATION_VM_RG=$1
    ;;  
-p|--port)
    shift
    JIT_OPERATION_VM_PORT=$1
    ;;  
--)
    shift
    break
    exit 0    
    ;;  
esac
shift
done


funcCheckArguments () {

  if [[ -z $JIT_OPERATION_TYPE ]]
  then 
    echo "Empty Operation Type"
    exit 1
  fi

  if [[ -z $JIT_OPERATION_VM ]]
  then
    echo "Empty VM Name"
    exit 1
  fi

  if [[ -z $JIT_OPERATION_VM_RG ]]
  then
    echo "Empty RG"
    exit 1
  fi
  
}



funcValidatePort () {

  if [ "$JIT_OPERATION_VM_PORT" -eq "$JIT_OPERATION_VM_PORT" ] 2>/dev/null
  then
      echo "$JIT_OPERATION_VM_PORT is an integer... good to go...."
  else
      echo "Value giving $JIT_OPERATION_VM_PORT for Port is invalid..."
      echo "Exiting"
      exit 1
  fi

}


funcGetAzureToken () {
  
  ## Azure Token
  AZURE_TOKEN=$(az account get-access-token --query accessToken -o tsv)

}


funcGetVmInformation () {

  ## Check if VM exists
  echo "Check if VM exists"
  ARR_OK=$(az vm list -o json | jq -r ".[] | select( .name == \"$JIT_OPERATION_VM\" ) | select ( .resourceGroup == \"$JIT_OPERATION_VM_RG\" ) | [ .id, .location ] | @tsv" | wc -l )

  if [[ "$ARR_OK" == "0" ]] 
  then 
     echo "$JIT_OPERATION_VM does not exist in RG: $JIT_OPERATION_VM_RG"
     echo "Exiting..."
     exit 1
  fi

  ARR=($(az vm list -o json | jq -r ".[] | select( .name == \"$JIT_OPERATION_VM\" ) | select ( .resourceGroup == \"$JIT_OPERATION_VM_RG\" ) | [ .id, .location ] | @tsv" | tr "," "\n"))

  ## Azure VM Settings
  AZURE_VM=${ARR[0]}
  AZURE_VM_LOCATION=${ARR[1]}
}


funcGetJit () {

  ## Get AZ VM RG
  echo "Get AZ VM RG"
  AZ_VM_RG=$(az vm list -o json | jq -r ".[] | ( select( .name == \"$JIT_OPERATION_VM\" )) | [ .resourceGroup ] | @tsv")
  

  ## Get AZ VM ID
  echo "Get AZ VM ID"
  AZ_VM_ID=$(az vm show --resource-group $AZ_VM_RG --name $JIT_OPERATION_VM --output json | jq -r "[.id] | @tsv")
  

  ## Get SUB ID
  echo "Get SUB ID"
  AZ_SUB_ID=$(echo $AZ_VM_ID | cut -d \/ -f 3)

  AZ_VM_ENDPOINT="https://management.azure.com/subscriptions/$AZ_SUB_ID/resourceGroups/$AZ_VM_RG/providers/Microsoft.Security/jitNetworkAccessPolicies?api-version=2020-01-01"
  
  JQ_STRING=".properties.virtualMachines[].id, \
  .name, \
  .properties.virtualMachines[].ports[].maxRequestAccessDuration, \
  .properties.virtualMachines[].ports[].number, \
  .properties.virtualMachines[].ports[].allowedSourceAddressPrefix"
  
  echo ""
  echo "All Details: "
  curl -sL -H "authorization: bearer $AZURE_TOKEN" -H "contenttype: application/json" "$AZ_VM_ENDPOINT" | jq ".value"
  
  echo ""
  echo ""
  echo "Just Relevant Information: "
  curl -sL -H "authorization: bearer $AZURE_TOKEN" -H "contenttype: application/json" "$AZ_VM_ENDPOINT" | \
      jq -r ".value[] | [ $JQ_STRING ] | @tsv" | column -t  
  
}



funcCreateVMJit () {

  ## Get AZ VM RG
  echo "Get AZ VM RG"
  AZ_VM_RG=$(az vm list -o json | jq -r ".[] | ( select( .name == \"$JIT_OPERATION_VM\" )) | [ .resourceGroup ] | @tsv")
 

  ## Get AZ VM ID
  echo "Get AZ VM ID"
  AZ_VM_ID=$(az vm show --resource-group $AZ_VM_RG --name $JIT_OPERATION_VM --output json | jq -r "[.id] | @tsv")


  ## Get SUB ID
  echo "Get SUB ID"
  AZ_SUB_ID=$(echo $AZ_VM_ID | cut -d \/ -f 3)
  

  ## Define VM Endpoint for Jit
  echo "Define VM Endpoint for Jit"
  AZ_VM_ENDPOINT="https://management.azure.com/subscriptions/$AZ_SUB_ID/resourceGroups/$AZ_VM_RG/providers/Microsoft.Security/locations/$AZURE_VM_LOCATION/jitNetworkAccessPolicies/$AZ_VM_JIT_POL_NAME?api-version=2020-01-01"
  
  ## Removing any existin Jit Json file
  echo "Removing any existin Jit Json file"
  rm -rf $AZURE_VM_JIT_CREATION_NAME 
  
  ## Create JIT Json file
  echo "Create JIT Json file"
  printf "
  {
    "kind": \"Basic\",
    "properties": {
      "virtualMachines": [
        {
          "id": \"$AZ_VM_ID\",
          "ports": [
            {
              "number": \"$JIT_OPERATION_VM_PORT\",
              "protocol": \"*\",
              "allowedSourceAddressPrefix": \"$MY_ISP_IP\",
              "maxRequestAccessDuration": \"$AZURE_VM_JIT_DURATION\"
            }
          ]
        }
      ]
    }
  }
  " >> $AZURE_VM_JIT_CREATION_NAME
  
  ## Execute Curl
  echo "Executing Curl Operation"
  curl -v -H "authorization: bearer $AZURE_TOKEN" -H "content-type: application/json"  --request PUT --data @$AZURE_VM_JIT_CREATION_NAME "$AZ_VM_ENDPOINT"

}




funcDeleteVmJit () {

  ## Get AZ VM RG
  echo "Get AZ VM RG"
  AZ_VM_RG=$(az vm list -o json | jq -r ".[] | ( select( .name == \"$JIT_OPERATION_VM\" )) | [ .resourceGroup ] | @tsv")


  ## Get AZ VM ID
  echo "Get AZ VM ID"
  AZ_VM_ID=$(az vm show --resource-group $AZ_VM_RG --name $JIT_OPERATION_VM --output json | jq -r "[.id] | @tsv")


  ## Get SUB ID
  echo "Get SUB ID"
  AZ_SUB_ID=$(echo $AZ_VM_ID | cut -d \/ -f 3)


  AZ_VM_ENDPOINT="https://management.azure.com/subscriptions/$AZ_SUB_ID/resourceGroups/$AZ_VM_RG/providers/Microsoft.Security/locations/$AZURE_VM_LOCATION/jitNetworkAccessPolicies/$AZ_VM_JIT_POL_NAME/?api-version=2020-01-01"

  ## Execute Curl
  echo "Executing Curl Operation"
  curl -v -X DELETE -H "authorization: bearer $AZURE_TOKEN" -H "content-type: application/json"  "$AZ_VM_ENDPOINT" 

}




funcInitiateVmJit () {

  ## Get AZ VM RG
  echo "Get AZ VM RG"
  AZ_VM_RG=$(az vm list -o json | jq -r ".[] | ( select( .name == \"$JIT_OPERATION_VM\" )) | [ .resourceGroup ] | @tsv")


  ## Get AZ VM ID
  echo "Get AZ VM ID"
  AZ_VM_ID=$(az vm show --resource-group $AZ_VM_RG --name $JIT_OPERATION_VM --output json | jq -r "[.id] | @tsv")


  ## Get SUB ID
  echo "Get SUB ID"
  AZ_SUB_ID=$(echo $AZ_VM_ID | cut -d \/ -f 3)


  ## Define VM Endpoint for Jit
  echo "Define VM Endpoint for Jit"
  AZ_VM_ENDPOINT="https://management.azure.com/subscriptions/$AZ_SUB_ID/resourceGroups/$AZ_VM_RG/providers/Microsoft.Security/locations/$AZURE_VM_LOCATION/jitNetworkAccessPolicies/$AZ_VM_JIT_POL_NAME/initiate?api-version=2020-01-01"


  ## Removing any existin Jit Json file
  echo "Removing any existin Jit Json file"
  rm -rf $AZURE_VM_JIT_INITIATE_NAME 

  ## Create JIT Json file
  echo "Create JIT Json file"
  printf "
  {
        "virtualMachines": [
        {
                "id": \"$AZ_VM_ID\",
                "ports": [
                        {
                        "number": \"$JIT_OPERATION_VM_PORT\",
                        "protocol": \"*\",
                        "allowedSourceAddressPrefix": \"$MY_ISP_IP\",
                        "duration": \"$AZURE_VM_JIT_DURATION\"
                        }
                ]
      }
    ],
        "justification": \"Access VM Today\"
  }
  " >> $AZURE_VM_JIT_INITIATE_NAME


  ## Execute Curl
  echo "Executing Curl Operation"
  curl -v -H "authorization: bearer $AZURE_TOKEN" -H "content-type: application/json"  --request POST --data @$AZURE_VM_JIT_INITIATE_NAME "$AZ_VM_ENDPOINT"

}




#######################################
## Core ###############################
#######################################



## Run ALl the time to validate Arguments
echo "Validating arguments"
funcCheckArguments 

## Apply Arguments logic
if [[ "$JIT_OPERATION_TYPE" == "init" ]]
then
   echo ""
   echo "Initialize JIT..."

   funcValidatePort

   funcGetVmInformation

   funcGetAzureToken

   funcInitiateVmJit

elif [[ "$JIT_OPERATION_TYPE" == "delete" ]]
then
   echo ""
   echo "Delete JIT"

   funcGetVmInformation

   funcGetAzureToken

   funcDeleteVmJit

elif [[ "$JIT_OPERATION_TYPE" == "create" ]]
then
    echo ""
    echo "Create JIT"

    funcValidatePort

    funcGetVmInformation

    funcGetAzureToken

    funcCreateVMJit    

elif [[ "$JIT_OPERATION_TYPE" == "status" ]]
then

    echo ""
    echo "GEt JIT Details and Status"
  
    funcGetVmInformation
 
    funcGetAzureToken

    funcGetJit

else

    echo "$JIT_OPERATION_TYPE is not a valid operation..."
    echo "Exiting"
    exit 1

fi

