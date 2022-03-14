#!/bin/bash


############################
## Functions ###############
############################


showHelp() {
cat << EOF  
Usage: 

bash create.sh --help/-h  [for help]
bash create.sh -o/--operation <create list delete> -g/--group <man-id-rg> -n/--name <man-id-name> -l/--location <man-id-rg-location>

Install Pre-requisites JQ

-h, -help,          --help                  Display help

-o, -operation,     --operation             Set operation type for Managed ID 
                                            create, list or delete

-g, -group,         --group                 Managed ID Resource Group Name            

-n, -name,          --name                  Managed ID Name

-l, -location       --location              Managed ID RG Location

EOF
}

options=$(getopt -l "help::,operation:,status:,group:,name:,location:" -o "h::o:g:n:l:" -a -- "$@")

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
    MID_OPERATION_TYPE=$1
    ;;  
-g|--group)
    shift
    MID_OPERATION_RG=$1
    ;;  
-n|--name)
    shift
    MID_OPERATION_NAME=$1
    ;;  
-l|--location)
    shift
    MID_OPERATION_RG_LOCAL=$1
    ;;
--)
    shift
    break
    exit 0    
    ;;  
esac
shift
done



funcCheckRG () {
  ## Check if RG Exists
  echo "Checking if RG $MID_OPERATION_RG exists..."
  EXISTS_RG=$(az group list \
    --output json | jq -r ".[] | select ( .name == \"$MID_OPERATION_RG\") | [ .id ] | @tsv" | wc -l)
}

funcCheckManId () {
  ## Check if Man ID Exists
  echo "Checking of ManID: $MID_OPERATION_NAME exists in RG: $MID_OPERATION_RG"
  EXISTS_NAME=$(az identity list \
    --output json | jq -r ".[] | select ( .name == \"$MID_OPERATION_NAME\" ) | [.name ] | @tsv" | wc -l)
}

funcCreateManId () {
  ## Creating Man ID
  echo "Creating Man ID with Name: $MID_OPERATION_NAME"
  az identity create \
    --resource-group  $MID_OPERATION_RG \
    --name $MID_OPERATION_NAME
}

funcListManId () {
  ## Listing Man ID
  echo "Listing Man ID"
  az identity list \
    --resource-group $MID_OPERATION_RG \
    --output json | jq -r ".[]"
}

funcDeleteManId () {
  ## Deleting Man ID
  echo "Delete Man ID with Name: $MID_OPERATION_NAME"

  az identity delete \
   --name $MID_OPERATION_NAME \
   --resource-group $MID_OPERATION_RG
}

funcDeleteManIdConfirm () {
  ## Confirm The deletion of Man ID
  echo "Confirm The deletion of Man ID $MID_OPERATION_NAME"
  
    
  while true ;
  do
    echo "Deleting Man ID: $MID_OPERATION_NAME in RG: $MID_OPERATION_RG"
    read -p "Confirm? <y/n> : " ansconf


    if [[ "$ansconf" != "y" ]] && [[ "$ansconf" != "n"  ]]
    then 
      echo "$ansconf is a Invalid Option"
      echo "Exiting"
      exit 3
    fi

    
    if [[ "$ansconf" == "n" ]]
    then
      echo "Exiting....."
      exit 3
    fi

    break    

  done
}



############################
## Core ####################
############################


if [[ "$MID_OPERATION_TYPE" == "list" ]]
then
   echo "Check if Man ID exists..."
   funcCheckManId
  
   if [[ "$EXISTS_NAME" == "0" ]]
   then
     echo "Managed ID: does not exist"
     echo "Exiting"
     exit 3
   fi

   echo "List Man ID Details..."
   funcListManId

elif [[ "$MID_OPERATION_TYPE" == "create"  ]]
then
   echo "RG $MID_OPERATION_RG does not exists"
   funcCheckRG

   echo "Check if Man ID exists..."
   funcCheckManId

   if [[ "$EXISTS_NAME" == "1" ]]
   then
     echo "Managed ID ALready does not exist"
     echo "Exiting"
     exit 3
   fi

   if [[ "$EXISTS_RG" == "0" ]]
   then
     echo "Creating RG: $MID_OPERATION_RG in Location: $MID_OPERATION_RG_LOCAL"

     az group create \
       --name $MID_OPERATION_RG \
       --location $MID_OPERATION_RG_LOCAL
   fi

   echo "Creating Man ID..."      
   funcCreateManId

elif [[ "$MID_OPERATION_TYPE" == "delete"  ]]
then
   echo "Deletion Operation"
   echo "Confirmin..."
   funcDeleteManIdConfirm

   echo "Deleting..."
   funcDeleteManId
else
   echo "No valid option to process..."
   echo "Exiting"
   exit 3
fi




