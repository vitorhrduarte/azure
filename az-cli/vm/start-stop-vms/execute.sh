##!/usr/bin/env bash

###############################
# Arrays - Start
###############################

declare -a RG_ARRAY
declare -a RG_ARRAY_VM_LIST

################################
# Arrays - End
################################

## Get Sub RG
RG_ARRAY=($(az group list --output json | jq -r ".[] | [ .name ] | @csv"))

## Declare RG Options List/Array
declare -a RG_ARRAY_OPTIONS

## Show Array options
for i in ${!RG_ARRAY[@]}
do
  RG_ARRAY_OPTIONS+=(${RG_ARRAY[$i]} $i)
done

## Define GUI Show RG in SUB
HEIGHT=30
WIDTH=90
CHOICE_HEIGHT=10
BACKTITLE="RG Details"
TITLE="Choose One RG"
MENU="Choose one of the following options:"

## Define User Choice
RG_CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${RG_ARRAY_OPTIONS[@]}" \
                2>&1 >/dev/tty)

## Parsing Choice
TMP_RG_CHOICE=${RG_CHOICE[0]}
TMP_RG_CHOICE_ARRAY=($(echo $TMP_RG_CHOICE | tr -d '"' |tr "," "\n"))

echo ""
PS3='Start(1) or Stop(2) VMS '
select result in 'Start' 'Stop'; do
  case $REPLY in
      [12])
          break
          ;;
      *)
          echo 'Invalid choice' >&2
  esac
done

REPLYOPERATION=$REPLY

echo ""
PS3='All(1) or One(2) VMS '
select result in 'All' 'One'; do
  case $REPLY in
      [12])
          break
          ;;
      *)  
          echo 'Invalid choice' >&2
  esac    
done

REPLYSCOPE=$REPLY

if [[ "$REPLYOPERATION" == "1" ]]; then
  echo "Start Operation in RG"

  if [[ "$REPLYSCOPE" == "1" ]]; then
  echo "Start All VMS in RG"	
  ARR_RG_VM_IDS=($(az vm list --resource-group ${TMP_RG_CHOICE_ARRAY[0]^^} --output json | jq  -r '.[] | [ .id ] | @tsv'))

  for i in ${ARR_RG_VM_IDS[@]}
  do
    echo "Starting VM ID: $i"
    TMP_VM_STATE=$(az vm get-instance-view --ids $i --output json | jq -r '.instanceView.statuses[] | select(.displayStatus | contains("VM")) | [ .displayStatus] | @tsv')
    
    if [[ "$TMP_VM_STATE" == "VM stopped" || "$TMP_VM_STATE" == "VM deallocated" ]]; then
      az vm start --ids $i ###--debug
    else
      echo "Skip ID: $i"
      echo "Already started"
    fi
  done

  fi
  
  if [[ "$REPLYSCOPE" == "2" ]]; then
  echo "Start One VM in RG" 
  ## Get RG VMS
  RG_ARRAY_VM_LIST=($(az vm list -d --output json | jq --arg rgn ${TMP_RG_CHOICE_ARRAY[0]^^} -r '.[] | select( .resourceGroup == $rgn ) | [ .name, .privateIps, .resourceGroup ] | @csv'))
  
  ## Declare RG Options List/Array
  declare -a RG_ARRAY_VM_LIST_OPTIONS
  
  ## Show Array options
  for i in ${!RG_ARRAY_VM_LIST[@]}
  do
    RG_ARRAY_VM_LIST_OPTIONS+=(${RG_ARRAY_VM_LIST[$i]} $i) 
  done
  
  ## Define GUI Show VMs in RG
  HEIGHT=30
  WIDTH=80
  CHOICE_HEIGHT=10
  BACKTITLE="RG VM Details"
  TITLE="Choose One VM"
  MENU="Choose one of the following options:"

  ## Define User Choice
  RG_VM_CHOICE=$(dialog --clear \
                  --backtitle "$BACKTITLE" \
                  --title "$TITLE" \
                  --menu "$MENU" \
                  $HEIGHT $WIDTH $CHOICE_HEIGHT \
                  "${RG_ARRAY_VM_LIST_OPTIONS[@]}" \
                  2>&1 >/dev/tty)
  
  ## Parsing Choice
  TMP_VM_CHOICE=${RG_VM_CHOICE[0]}
  TMP_VM_CHOICE_ARRAY=($(echo $TMP_VM_CHOICE | tr -d '"' |tr "," "\n"))

  ARR_RG_VM_IDS=($(az vm list --resource-group ${TMP_RG_CHOICE_ARRAY[0]^^} --output json | jq --arg vmn ${TMP_VM_CHOICE_ARRAY[0]} -r '.[] | select( .name == $vmn ) | [ .id ] | @tsv'))
 
  for i in ${ARR_RG_VM_IDS[@]}
  do
    TMP_VM_STATE=$(az vm get-instance-view --ids $i --output json | jq -r '.instanceView.statuses[] | select(.displayStatus | contains("VM")) | [ .displayStatus] | @tsv') 
 
    if [[ "$TMP_VM_STATE" == "VM stopped" || "$TMP_VM_STATE" == "VM deallocated" ]]; then
      echo "Starting VM ID: $i"
      az vm start --ids $i ###--debug
    else
      echo "Skip, VM already Started"
    fi
  done

  fi
fi

if [[ "$REPLYOPERATION" == "2" ]]; then
  
  if [[ "$REPLYSCOPE" == "1" ]]; then
    echo "Stop All VMS in RG"    
    ARR_RG_VM_IDS=($(az vm list --resource-group ${TMP_RG_CHOICE_ARRAY[0]^^} --output json | jq  -r '.[] | [ .id ] | @tsv'))

    for i in ${ARR_RG_VM_IDS[@]}
    do
      TMP_VM_STATE=$(az vm get-instance-view --ids $i --output json | jq -r '.instanceView.statuses[] | select(.displayStatus | contains("VM")) | [ .displayStatus] | @tsv')   
  
      if [[ "$TMP_VM_STATE" == "VM running" || "$TMP_VM_STATE" == "VM stopped" ]]; then
        echo "Stoping VM ID: $i"
        az vm stop --ids $i ###--debug
        echo "Deallocating VM ID: $i"
        az vm deallocate --ids $i ###--debug
      else
        echo "Skip VM, already stopped and deallocated"
      fi
    done
  fi

  if [[ "$REPLYSCOPE" == "2" ]]; then
    echo "Stop One VM in RG" 
    ## Get RG VMS
    RG_ARRAY_VM_LIST=($(az vm list -d --output json | jq --arg rgn ${TMP_RG_CHOICE_ARRAY[0]^^} -r '.[] | select( .resourceGroup == $rgn ) | [ .name, .privateIps, .resourceGroup ] | @csv'))

    ## Declare RG Options List/Array
    declare -a RG_ARRAY_VM_LIST_OPTIONS

    ## Show Array options
    for i in ${!RG_ARRAY_VM_LIST[@]}
    do
      RG_ARRAY_VM_LIST_OPTIONS+=(${RG_ARRAY_VM_LIST[$i]} $i)
    done
  
    ## Define GUI Show VMs in RG
    HEIGHT=30
    WIDTH=80
    CHOICE_HEIGHT=10
    BACKTITLE="RG VM Details"
    TITLE="Choose One VM"
    MENU="Choose one of the following options:"
  
    ## Define User Choice
    RG_VM_CHOICE=$(dialog --clear \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${RG_ARRAY_VM_LIST_OPTIONS[@]}" \
                  2>&1 >/dev/tty)
    
    ## Parsing Choice
    TMP_VM_CHOICE=${RG_VM_CHOICE[0]}
    TMP_VM_CHOICE_ARRAY=($(echo $TMP_VM_CHOICE | tr -d '"' |tr "," "\n"))
  
    ARR_RG_VM_IDS=($(az vm list --resource-group ${TMP_RG_CHOICE_ARRAY[0]^^} --output json | jq --arg vmn ${TMP_VM_CHOICE_ARRAY[0]} -r '.[] | select( .name == $vmn ) | [ .id ] | @tsv'))
    
    for i in ${ARR_RG_VM_IDS[@]}
    do
      TMP_VM_STATE=$(az vm get-instance-view --ids $i --output json | jq -r '.instanceView.statuses[] | select(.displayStatus | contains("VM")) | [ .displayStatus] | @tsv')
     
      echo "$TMP_VM_STATE"
 
      if [[ "$TMP_VM_STATE" == "VM running" || "$TMP_VM_STATE" == "VM stopped"  ]]; then
        echo "Stoping VM ID: $i" 
        az vm stop --ids $i ###--debug
        echo "Deallocate VM ID: $i"
        az vm deallocate --ids $i ###--debug
      else
        echo "Skip VM, already stopped and deallocated"
      fi
    done
  fi
fi
