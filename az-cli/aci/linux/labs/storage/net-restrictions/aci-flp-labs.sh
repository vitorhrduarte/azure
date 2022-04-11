#!/bi/bash

# script name: aci-flp-labs.sh
# Version v0.0.2 20220204
# Set of tools to deploy ACI troubleshooting labs

# "-l|--lab" Lab scenario to deploy
# "-r|--region" region to deploy the resources
# "-u|--user" User alias to add on the lab name
# "-h|--help" help info
# "--version" print version

# read the options
TEMP=`getopt -o g:n:l:r:u:hv --long resource-group:,name:,lab:,region:,user:,help,validate,version -n 'aci-flp-labs.sh' -- "$@"`
eval set -- "$TEMP"

# set an initial value for the flags
RESOURCE_GROUP=""
ACI_NAME=""
LAB_SCENARIO=""
USER_ALIAS=""
LOCATION="uksouth"
VALIDATE=0
HELP=0
VERSION=0

while true ;
do
    case "$1" in
        -h|--help) HELP=1; shift;;
        -g|--resource-group) case "$2" in
            "") shift 2;;
            *) RESOURCE_GROUP="$2"; shift 2;;
            esac;;
        -n|--name) case "$2" in
            "") shift 2;;
            *) ACI_NAME="$2"; shift 2;;
            esac;;
        -l|--lab) case "$2" in
            "") shift 2;;
            *) LAB_SCENARIO="$2"; shift 2;;
            esac;;
        -r|--region) case "$2" in
            "") shift 2;;
            *) LOCATION="$2"; shift 2;;
            esac;;
        -u|--user) case "$2" in
            "") shift 2;;
            *) USER_ALIAS="$2"; shift 2;;
            esac;;    
        -v|--validate) VALIDATE=1; shift;;
        --version) VERSION=1; shift;;
        --) shift ; break ;;
        *) echo -e "Error: invalid argument\n" ; exit 3 ;;
    esac
done

# Variable definition
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
SCRIPT_NAME="$(echo $0 | sed 's|\.\/||g')"
SCRIPT_VERSION="Version v0.0.2 20220204"

# Funtion definition

# az login check
function az_login_check () {
    if $(az account list 2>&1 | grep -q 'az login')
    then
        echo -e "\n--> Warning: You have to login first with the 'az login' command before you can run this lab tool\n"
        az login -o table
    fi
}

# check resource group and aci
function check_resourcegroup_cluster () {
    RESOURCE_GROUP="$1"
    ACI_NAME="$2"

    RG_EXIST=$(az group show -g $RESOURCE_GROUP &>/dev/null; echo $?)
    if [ $RG_EXIST -ne 0 ]
    then
        echo -e "\n--> Creating resource group ${RESOURCE_GROUP}...\n"
        az group create --name $RESOURCE_GROUP --location $LOCATION -o table &>/dev/null
    else
        echo -e "\nResource group $RESOURCE_GROUP already exists...\n"
    fi

    ACI_EXIST=$(az container show -g $RESOURCE_GROUP -n $ACI_NAME &>/dev/null; echo $?)
    if [ $ACI_EXIST -eq 0 ]
    then
        echo -e "\n--> Container instance $ACI_NAME already exists...\n"
        echo -e "Please remove that one before you can proceed with the lab.\n"
        exit 5
    fi
}

# validate ACI exists
function validate_aci_exists () {
    RESOURCE_GROUP="$1"
    ACI_NAME="$2"

    ACI_EXIST=$(az container show -g $RESOURCE_GROUP -n $ACI_NAME &>/dev/null; echo $?)
    if [ $ACI_EXIST -ne 0 ]
    then
        echo -e "\n--> ERROR: Failed to create container instance $ACI_NAME in resource group $RESOURCE_GROUP ...\n"
        exit 5
    fi
}

# Usage text
function print_usage_text () {
    NAME_EXEC="aci-flp-labs"
    echo -e "$NAME_EXEC usage: $NAME_EXEC -l <LAB#> -u <USER_ALIAS> [-v|--validate] [-r|--region] [-h|--help] [--version]\n"
    echo -e "\nHere is the list of current labs available:\n
*************************************************************************************
*\t 1. ACI deployment on existing resource group fails
*\t 2. ACI deployed with wrong image
*\t 3. ACI deployment with Azure Log Analytics
*\t 4. TBA
*************************************************************************************\n"
}

# Lab scenario 1
function lab_scenario_1 () {
    ACI_NAME=aci-labs-ex${LAB_SCENARIO}-${USER_ALIAS}
    RESOURCE_GROUP=aci-labs-ex${LAB_SCENARIO}-rg-${USER_ALIAS}
    check_resourcegroup_cluster $RESOURCE_GROUP $ACI_NAME

    echo -e "\n--> Deploying resources for lab${LAB_SCENARIO}...\n"

    az container create \
    --name $ACI_NAME \
    --resource-group $RESOURCE_GROUP \
    --image mcr.microsoft.com/azuredocs/aci-helloworld \
    --vnet aci-vnet-lab200aci \
    --vnet-address-prefix 10.0.0.0/16 \
    --subnet aci-subnet-lab200aci \
    --subnet-address-prefix 10.0.0.0/24 \
    -o table

    validate_aci_exists $RESOURCE_GROUP $ACI_NAME
    
    SUBNET_ID=$(az container show -g $RESOURCE_GROUP -n $ACI_NAME --query subnetIds[].id -o tsv)

cat <<EOF > aci.yaml
apiVersion: '2021-07-01'
location: $LOCATION
name: appcontaineryaml
properties:
  containers:
  - name: appcontaineryaml
    properties:
      image: mcr.microsoft.com/azuredocs/aci-helloworld
      ports:
      - port: 80
        protocol: TCP
      resources:
        requests:
          cpu: 1.0
          memoryInGB: 1.5
  ipAddress:
    type: Public
    ports:
    - protocol: tcp
      port: '80'
  osType: Linux
  restartPolicy: Always
  subnetIds:
    - id: $SUBNET_ID
      name: default
tags: null
type: Microsoft.ContainerInstance/containerGroups
EOF

    ERROR_MESSAGE="$(az container create --resource-group $RESOURCE_GROUP --file aci.yaml 2>&1)"
    
    echo -e "\n\n************************************************************************\n"
    echo -e "\n--> Issue description: \n Customer has an ACI alredy deployed in the resource group $RESOURCE_GROUP and he wants to deploy another one in the same resource group using the following:"
    echo -e "az container create --resource-group $RESOURCE_GROUP --file aci.yaml\n"
    echo -e "Cx is getting the error message:"
    echo -e "\n-------------------------------------------------------------------------------------\n"
    echo -e "$ERROR_MESSAGE"
    echo -e "\n-------------------------------------------------------------------------------------\n"
    echo -e "The yaml file aci.yaml is in your current path, you have to modified it in order to be able to deploy the second container instance \"appcontaineryaml\"\n"
    echo -e "Once you find the issue, update the aci.yaml file and run the commnad:"
    echo -e "az container create --resource-group $RESOURCE_GROUP --file aci.yaml\n"
}

function lab_scenario_1_validation () {
    ACI_NAME=aci-labs-ex${LAB_SCENARIO}-${USER_ALIAS}
    RESOURCE_GROUP=aci-labs-ex${LAB_SCENARIO}-rg-${USER_ALIAS}
    validate_aci_exists $RESOURCE_GROUP $ACI_NAME

    ACI_STATUS=$(az container show -g $RESOURCE_GROUP -n appcontaineryaml &>/dev/null; echo $?)
    if [ $ACI_STATUS -eq 0 ]
    then
        echo -e "\n\n========================================================"
        echo -e '\nContainer instance "appcontaineryaml" looks good now!\n'
    else
        echo -e "\n--> Error: Scenario $LAB_SCENARIO is still FAILED\n\n"
        echo -e "The yaml file aci.yaml is in your current path, you have to modified it in order to be able to deploy the second container instance \"appcontaineryaml\"\n"
        echo -e "Once you find the issue, update the aci.yaml file and run the commnad:"
        echo -e "az container create --resource-group $RESOURCE_GROUP --file aci.yaml\n"
    fi
}

# Lab scenario 2
function lab_scenario_2 () {
    ACI_NAME=aci-labs-ex${LAB_SCENARIO}-${USER_ALIAS}
    RESOURCE_GROUP=aci-labs-ex${LAB_SCENARIO}-rg-${USER_ALIAS}
    check_resourcegroup_cluster $RESOURCE_GROUP $ACI_NAME

    echo -e "\n--> Deploying cluster for lab${LAB_SCENARIO}...\n"
    az container create \
    --name $ACI_NAME \
    --resource-group $RESOURCE_GROUP \
    --image alpine \
    --ports 80 \
    -o table &>/dev/null

    validate_aci_exists $RESOURCE_GROUP $ACI_NAME
    ACI_URI=$(az container show -g $RESOURCE_GROUP -n $ACI_NAME --query id -o tsv 2>/dev/null)
    
    echo -e "\n\n********************************************************"
    echo -e "\n--> Issue description: \nAn ACI has been deployed with name $ACI_NAME in the resourece group $RESOURCE_GROUP, and it keeps restarting."
    echo -e "Looks like it was deployed with the wrong image."
    echo -e "You have to update the ACI to change the image to nginx.\n"
    echo -e "ACI URI=${ACI_URI}\n"
}

function lab_scenario_2_validation () {
    ACI_NAME=aci-labs-ex${LAB_SCENARIO}-${USER_ALIAS}
    RESOURCE_GROUP=aci-labs-ex${LAB_SCENARIO}-rg-${USER_ALIAS}
    validate_aci_exists $RESOURCE_GROUP $ACI_NAME

    ACI_IMAGE="$(az container show -g $RESOURCE_GROUP -n $ACI_NAME --query containers[].image -o tsv)"
    RESTART_COUNT="$(az container show -g $RESOURCE_GROUP -n $ACI_NAME --query containers[].instanceView.restartCount -o tsv)"
    ACI_STATUS=$(az container show -g $RESOURCE_GROUP -n $ACI_NAME &>/dev/null; echo $?)
    if [ $ACI_STATUS -eq 0 ] && [[ "$ACI_IMAGE" == "nginx"* ]] && [ $RESTART_COUNT -eq 0 ]
    then
        echo -e "\n\n========================================================"
        echo -e "\nContainer instance \"${ACI_NAME}\" looks good now!\n"
    else
        echo -e "\n--> Error: Scenario $LAB_SCENARIO is still FAILED\n\n"
    fi
}

# Lab scenario 3
function lab_scenario_3 () {
    ACI_NAME="appcontaineryaml"
    RESOURCE_GROUP=aci-labs-ex${LAB_SCENARIO}-rg-${USER_ALIAS}
    LOG_WKS_NAME=aci-wks-labs-ex-${LAB_SCENARIO}-${USER_ALIAS}
    ACI_LENGTH_STRING=12
    ACI_CONTAINER_DNS_LABEL=$(tr -dc a-z </dev/urandom | head -c $ACI_LENGTH_STRING)
    ACI_CONTAINER_IMAGE="mcr.microsoft.com/azuredocs/aci-helloworld"

    check_resourcegroup_cluster $RESOURCE_GROUP $ACI_NAME

    echo -e "\n--> Deploying cluster for lab${LAB_SCENARIO}...\n"
    
    ## Create Log Analytics WorkSpace
    az monitor log-analytics workspace create \
      --resource-group $RESOURCE_GROUP \
      --workspace-name $LOG_WKS_NAME \
      --location $LOCATION \
      --sku PerGB2018 &>/dev/null 

    ## Remove any previous aci.yaml file
    rm -rf aci.yaml

cat <<EOF > aci.yaml
apiVersion: '2021-07-01'
location: $LOCATION
name: $ACI_NAME
properties:
  containers:
  - name: $ACI_NAME
    properties:
      image: mcr.microsoft.com/azuredocs/aci-helloworld
      ports:
      - port: 80
        protocol: TCP
      resources:
        requests:
          cpu: 1.0
          memoryInGB: 1.5
  ipAddress:
    type: Public
    ports:
    - protocol: tcp
      port: '80'
  osType: Linux
  restartPolicy: Always
  diagnostics:
    logAnalytics:
      workspaceId: $LOG_WKS_NAME
      workspaceKey: "35452wrfcefwqteq45rqwfat4"
tags: null
type: Microsoft.ContainerInstance/containerGroups
EOF

    ERROR_MESSAGE="$(az container create --resource-group $RESOURCE_GROUP --file aci.yaml 2>&1)"

    echo -e "\n\n********************************************************"
    echo -e "\n--> Issue description: \n Customer wants to deploy an ACI using the following:"
    echo -e "az container create --resource-group $RESOURCE_GROUP --file aci.yaml\n"
    echo -e "Cx is getting the error message:"
    echo -e "\n-------------------------------------------------------------------------------------\n"
    echo $ERROR_MESSAGE
    echo -e "\n-------------------------------------------------------------------------------------\n"
    echo -e "The yaml file aci.yaml is in your current path, you have to modified it in order to be able to deploy the second container instance \"appcontaineryaml\"\n"
    echo -e "Once you find the issue, update the aci.yaml file and run the commnad:"
    echo -e "az container create --resource-group $RESOURCE_GROUP --file aci.yaml\n"

}

function lab_scenario_3_validation () {
    
    ACI_NAME="appcontaineryaml"
    RESOURCE_GROUP=aci-labs-ex${LAB_SCENARIO}-rg-${USER_ALIAS}

    validate_aci_exists $RESOURCE_GROUP $ACI_NAME

    ACI_STATUS=$(az container show -g $RESOURCE_GROUP -n $ACI_NAME &>/dev/null; echo $?)
   
    if [ $ACI_STATUS -eq 0 ]
    then
        echo -e "\n\n========================================================"
        echo -e '\nContainer instance "appcontaineryaml" looks good now!\n'
    else
        echo -e "\n--> Error: Scenario $LAB_SCENARIO is still FAILED\n\n"
        echo -e "The yaml file aci.yaml is in your current path, you have to modified it in order to be able to deploy the second container instance \"appcontaineryaml\"\n"
        echo -e "Once you find the issue, update the aci.yaml file and run the commnad:"
        echo -e "az container create --resource-group $RESOURCE_GROUP --file aci.yaml\n"
    fi

}






# Lab scenario 4
function lab_scenario_4 () {

    ACI_NAME="appcontaineryaml"
    RESOURCE_GROUP=aci-labs-ex${LAB_SCENARIO}-rg-${USER_ALIAS}
    ACI_LENGTH_STRING=12
    ACI_CONTAINER_DNS_LABEL=$(tr -dc a-z </dev/urandom | head -c $ACI_LENGTH_STRING)
    ACI_CONTAINER_IMAGE="mcr.microsoft.com/azuredocs/aci-helloworld"

    echo -e "\n--> Deploying cluster for lab${LAB_SCENARIO}...\n"
    
    ## Remove any previous aci.yaml file
    rm -rf aci.yaml

cat <<EOF > aci.yaml
apiVersion: '2021-07-01'
location: $LOCATION
name: $ACI_NAME
properties:
  containers:
  - name: $ACI_NAME
    properties:
      image: mcr.microsoft.com/azuredocs/aci-helloworld
      ports:
      - port: 80
        protocol: TCP
      resources:
        requests:
          cpu: 1.0
          memoryInGB: 1.5
  ipAddress:
    type: Public
    ports:
    - protocol: tcp
      port: '80'
  osType: Linux
  restartPolicy: Always
tags: null
type: Microsoft.ContainerInstance/containerGroups
EOF

    ERROR_MESSAGE="$(az container create --resource-group $RESOURCE_GROUP --file aci.yaml 2>&1)"

    echo -e "\n\n********************************************************"
    echo -e "\n--> Issue description: \n Customer wants to deploy an ACI using the following:"
    echo -e "az container create --resource-group $RESOURCE_GROUP --file aci.yaml\n"
    echo -e "Cx is getting the error message:"
    echo -e "\n-------------------------------------------------------------------------------------\n"
    echo $ERROR_MESSAGE
    echo -e "\n-------------------------------------------------------------------------------------\n"
    echo -e "The yaml file aci.yaml is in your current path, you have to modified it in order to be able to deploo
y the second container instance \"appcontaineryaml\"\n"
    echo -e "Once you find the issue, update the aci.yaml file and run the commnad:"
    echo -e "az container create --resource-group $RESOURCE_GROUP --file aci.yaml\n"
}


function lab_scenario_4_validation () {

    ACI_NAME="appcontaineryaml"
    RESOURCE_GROUP=aci-labs-ex${LAB_SCENARIO}-rg-${USER_ALIAS}

    validate_aci_exists $RESOURCE_GROUP $ACI_NAME

    ACI_STATUS=$(az container show -g $RESOURCE_GROUP -n $ACI_NAME &>/dev/null; echo $?)

    if [ $ACI_STATUS -eq 0 ]
    then
        echo -e "\n\n========================================================"
        echo -e '\nContainer instance "appcontaineryaml" looks good now!\n'
    else
        echo -e "\n--> Error: Scenario $LAB_SCENARIO is still FAILED\n\n"
        echo -e "The yaml file aci.yaml is in your current path, you have to modified it in order to be able to dd
eploy the second container instance \"appcontaineryaml\"\n"
        echo -e "Once you find the issue, update the aci.yaml file and run the commnad:"
        echo -e "az container create --resource-group $RESOURCE_GROUP --file aci.yaml\n"
    fi

}








# Lab scenario 5
function lab_scenario_5 () {
  ACI_SP_NAME="sp-aci-lab5"
  ACI_NAME="mycontainer"
  RESOURCE_GROUP=aci-labs-ex${LAB_SCENARIO}-rg-${USER_ALIAS}

  check_resourcegroup_cluster $RESOURCE_GROUP $ACI_NAME

  echo -e "\n--> Deploying resources for lab${LAB_SCENARIO}...\n"

  ACI_RG_URI=$(az group list \
   --output json | jq -r ".[] | select ( .name == \"$RESOURCE_GROUP\") | [ .id] | @tsv")


  declare -a ARR_SP_DETAILS

  ARR_SP_DETAILS=($(az ad sp create-for-rbac \
  --name $ACI_SP_NAME \
  --role Reader \
  --scopes $ACI_RG_URI 2>/dev/null | jq -r ". | [ .password, .appId , .displayName ] | @tsv"))

  TENANT=$(az account list \
    --output json | jq -r ".[] | select ( .isDefault == "true" ) | [ .tenantId] | @tsv")

  #For Debug
  #echo ${ARR_SP_DETAILS[0]}
  #echo ${ARR_SP_DETAILS[1]}
  #echo ${ARR_SP_DETAILS[2]}
  #echo $TENANT

  AZ_LOGIN_STRING=$(echo "az login --service-principal --username ${ARR_SP_DETAILS[1]} --password ${ARR_SP_DETAILS[0]} --tenant $TENANT") 

  #"Login With Another SP"
  bash $AZ_LOGIN_STRING &>/dev/null

  ## Create Container
  ERROR_MESSAGE="$(az container create \
    --resource-group $RESOURCE_GROUP \
    --name $ACI_NAME \
    --image mcr.microsoft.com/azure-cli \
    --command-line "sleep infinity" 2>&1)"  

  echo -e "\n\n************************************************************************\n"
  echo -e "\n--> Issue description: \n Customer needs to deploy an ACI in the resource group $RESOURCE_GROUP"
  echo -e "az container create --resource-group $RESOURCE_GROUP --name $ACI_NAME --image mcr.microsoft.com/azure-cli --command-line \"tail -f /dev/null\"\n"
  echo -e "Cx is getting the error message:"
  echo -e "\n-------------------------------------------------------------------------------------\n"
  echo -e "$ERROR_MESSAGE"
  echo -e "\n-------------------------------------------------------------------------------------\n"
  echo -e "Once you find the issue, run again the previous command to deploy ACI"

}


function lab_scenario_5_validation () {
  ACI_SP_NAME="sp-aci-lab5"
  ACI_NAME="mycontainer"
  RESOURCE_GROUP=aci-labs-ex${LAB_SCENARIO}-rg-${USER_ALIAS}

  ## Test se ACI corre com SP criado
  ACI_STATUS=$(az container list \
    --output json  | jq -r ".[] | select ( .name == \"$ACI_NAME\" ) | select ( .resourceGroup == \"$RESOURCE_GROUP\") | [ .id] | @tsv" | wc -l) 


  if [[ "$ACI_STATUS" == "1" ]]
  then
        echo -e "\n\n========================================================"
        echo -e "\nContainer instance $ACI_NAME looks good now!\n"
  else
        echo -e "\n--> Error: Scenario $LAB_SCENARIO is still FAILED\n\n"
        echo -e "Once you find the issue, run agains the $LAB_SCENARIO"
  fi

}









# Lab scenario 6
function lab_scenario_6 () {






}






























# Lab scenario 7
function lab_scenario_7 () {

  # Change these four parameters as needed
  ACI_NAME=aci-labs-ex${LAB_SCENARIO}-${USER_ALIAS}
  ACI_PERS_RESOURCE_GROUP=aci-labs-ex${LAB_SCENARIO}-rg-${USER_ALIAS}
  ACI_PERS_STORAGE_ACCOUNT_NAME=acilab7m1aol$RANDOM
  ACI_PERS_LOCATION=westeurope
  ACI_PERS_SHARE_NAME=acishare
  ACI_DNS_NAME="$ACI_PERS_STORAGE_ACCOUNT_NAME"

  check_resourcegroup_cluster $ACI_PERS_RESOURCE_GROUP $ACI_NAME
 
  echo -e "\n--> Deploying resources for lab${LAB_SCENARIO}...\n"


  # Create the storage account with the parameters
  # echo "Create the storage account with the parameters"
  az storage account create \
    --resource-group $ACI_PERS_RESOURCE_GROUP \
    --name $ACI_PERS_STORAGE_ACCOUNT_NAME \
    --location $ACI_PERS_LOCATION \
    --sku Standard_LRS 2>&1


  # Create the file share
  # echo "Create the file share "
  az storage share create \
    --name $ACI_PERS_SHARE_NAME \
    --account-name $ACI_PERS_STORAGE_ACCOUNT_NAME 2>&1


  # echo "Get Stor Key"
  STORAGE_KEY=$(az storage account keys list \
    --resource-group $ACI_PERS_RESOURCE_GROUP \
    --account-name $ACI_PERS_STORAGE_ACCOUNT_NAME \
    --query "[0].value" \
    --output tsv 2>&1)


  # echo "Change Stor Key"
  # Change the char in position 10 to letter a
  INDEX=10
  STORAGE_KEY=$( echo $STORAGE_KEY | sed 's/\(.\{'$INDEX'\}\)./\1a/' 2>&1 )


  # Yaml to Deploy
  # echo "Yaml to Deploy"

cat <<EOF > aci.yaml
apiVersion: '2019-12-01'
location: $ACI_PERS_LOCATION
name: $ACI_NAME
properties:
  containers:
  - name: hellofiles
    properties:
      environmentVariables: []
      image: mcr.microsoft.com/azuredocs/aci-hellofiles
      ports:
      - port: 80
      resources:
        requests:
          cpu: 1.0
          memoryInGB: 1.5
      volumeMounts:
      - mountPath: /aci/logs/
        name: filesharevolume
  osType: Linux
  restartPolicy: Always
  ipAddress:
    type: Public
    ports:
      - port: 80
    dnsNameLabel: $ACI_DNS_NAME
  volumes:
  - name: filesharevolume
    azureFile:
      sharename: acishare
      storageAccountName: $ACI_PERS_STORAGE_ACCOUNT_NAME
      storageAccountKey: $STORAGE_KEY
tags: {}
type: Microsoft.ContainerInstance/containerGroups
EOF


  # Deploy ACI Container
  # echo "Deploy ACI Container"
  # Deploy with YAML template
  ERROR_MESSAGE="$(az container create \
    --resource-group $ACI_PERS_RESOURCE_GROUP \
    --file aci.yaml 2>&1)"


    echo -e "\n\n************************************************************************\n"
    echo -e "\n--> Issue description: \n Customer wants to deploy an ACI in the resource group $RESOURCE_GROUP and he wants to mount a file share:"
    echo -e "az container create --resource-group $RESOURCE_GROUP --file aci.yaml\n"
    echo -e "Cx is getting the error message:"
    echo -e "\n-------------------------------------------------------------------------------------\n"
    echo -e "$ERROR_MESSAGE"
    echo -e "\n-------------------------------------------------------------------------------------\n"
    echo -e "The yaml file aci.yaml is in your current path, you have to modified it in order to be able to deploy it\n"
    echo -e "Once you find the issue, update the aci.yaml file and run the commnad:"
    echo -e "az container create --resource-group $RESOURCE_GROUP --file aci.yaml\n"  

}


function lab_scenario_7_validation () {

   ACI_NAME=aci-labs-ex${LAB_SCENARIO}-${USER_ALIAS}
   RESOURCE_GROUP=aci-labs-ex${LAB_SCENARIO}-rg-${USER_ALIAS}
  
   validate_aci_exists $RESOURCE_GROUP $ACI_NAME

   ACI_STATUS=$(az container show -g $RESOURCE_GROUP -n $ACI_NAME  &>/dev/null; echo $?)
   if [ $ACI_STATUS -eq 0 ]
   then
       echo -e "\n\n========================================================"
       echo -e "\nContainer instance "$ACI_NAME" looks good now!\n"
   else
       echo -e "\n--> Error: Scenario $LAB_SCENARIO is still FAILED\n\n"
       echo -e "The yaml file aci.yaml is in your current path, you have to modified it in order to be able to deploy it""\n"
       echo -e "Once you find the issue, update the aci.yaml file and run the commnad:"
       echo -e "az container create --resource-group $RESOURCE_GROUP --file aci.yaml\n"
   fi
}




#if -h | --help option is selected usage will be displayed
if [ $HELP -eq 1 ]
then
	print_usage_text
    echo -e '"-l|--lab" Lab scenario to deploy (3 possible options)
"-r|--region" region to create the resources
"--version" print version of aci-flp-labs
"-h|--help" help info\n'
	exit 0
fi

if [ $VERSION -eq 1 ]
then
	echo -e "$SCRIPT_VERSION\n"
	exit 0
fi

if [ -z $LAB_SCENARIO ]; then
	echo -e "\n--> Error: Lab scenario value must be provided. \n"
	print_usage_text
	exit 9
fi

if [ -z $USER_ALIAS ]; then
	echo -e "Error: User alias value must be provided. \n"
	print_usage_text
	exit 10
fi

# lab scenario has a valid option
if [[ ! $LAB_SCENARIO =~ ^[1-7]+$ ]];
then
    echo -e "\n--> Error: invalid value for lab scenario '-l $LAB_SCENARIO'\nIt must be value from 1 to 2\n"
    exit 11
fi

# main
echo -e "\n--> ACI Troubleshooting sessions
********************************************

This tool will use your default subscription to deploy the lab environments.
Verifing if you are authenticated already...\n"

# Verify az cli has been authenticated
az_login_check

if [ $LAB_SCENARIO -eq 1 ] && [ $VALIDATE -eq 0 ]
then
    check_resourcegroup_cluster
    lab_scenario_1

elif [ $LAB_SCENARIO -eq 1 ] && [ $VALIDATE -eq 1 ]
then
    lab_scenario_1_validation

elif [ $LAB_SCENARIO -eq 2 ] && [ $VALIDATE -eq 0 ]
then
    check_resourcegroup_cluster
    lab_scenario_2

elif [ $LAB_SCENARIO -eq 2 ] && [ $VALIDATE -eq 1 ]
then
    lab_scenario_2_validation

elif [ $LAB_SCENARIO -eq 3 ] && [ $VALIDATE -eq 0 ]
then
    check_resourcegroup_cluster
    lab_scenario_3

elif [ $LAB_SCENARIO -eq 3 ] && [ $VALIDATE -eq 1 ]
then
    lab_scenario_3_validation

elif [ $LAB_SCENARIO -eq 4 ] && [ $VALIDATE -eq 0 ]
then
    lab_scenario_4

elif [ $LAB_SCENARIO -eq 4 ] && [ $VALIDATE -eq 1 ]
then
    lab_scenario_4_validation

elif [ $LAB_SCENARIO -eq 5 ] && [ $VALIDATE -eq 0 ] 
then
    lab_scenario_5

elif [ $LAB_SCENARIO -eq 5 ] && [ $VALIDATE -eq 1 ] 
then
    lab_scenario_5_validation

elif [ $LAB_SCENARIO -eq 7 ] && [ $VALIDATE -eq 0 ]
then
    lab_scenario_7

elif [ $LAB_SCENARIO -eq 7 ] && [ $VALIDATE -eq 1 ]
then
    lab_scenario_7_validation

else
    echo -e "\n--> Error: no valid option provided\n"
    exit 12
fi

exit 0
