#!/bin/bash

showHelp() {
cat << EOF  
Usage: 

bash start-stop-aks.sh --help/-h  [for help]
bash start-stop-aks.sh -o/--operation <start stop status> -s/--scope <all one>

Install Pre-requisites jq and dialog

-h, -help,          --help                  Display help

-o, -operation,     --operation             Set operation type for the AKS cluster
                                            start or stop Or status

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


function printTable()
{
    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                # Add Line Delimiter

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                # Add Header Or Body

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                # Add Line Delimiter

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | sed 's/^  //' | awk '/^\+/{gsub(" ", "-", $0)}1' 
            fi
        fi
    fi
}

function removeEmptyLines()
{
    local -r content="${1}"

    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString()
{
    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString()
{
    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString()
{
    local -r string="${1}"

    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}


OPER_TYPE=(start stop status)
OPER_SCOPE=(all one)

FIRST_MATCH=0
SECOND_MATCH=0
for oper in "${OPER_TYPE[@]}"; do
    if [[ $oper = "$AKS_OPERATION_TYPE" ]]; then
        FIRST_MATCH=1
        echo "Operation Found... continue..."

        if [[ $oper = "status" ]]; then
          echo "Just Status"
          break
        fi
        

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
  
  declare -a AKS_STATUS_ARRAY
  AKS_STATUS_ARRAY=("ClusterName,RG,Status")

  for akscl in "${AKS_ARRAY[@]}"; do
     AKS_CL_ARRAY=($(echo $akscl | tr -d '"' |tr "," "\n"))
  
     ## Execute Show Status
     AKS_STATUS=$(az aks show --name ${AKS_CL_ARRAY[0]} --resource-group ${AKS_CL_ARRAY[1]} -o json | jq -r '.powerState.code')
     #echo "AKS Cluster ${AKS_CL_ARRAY[0]} in RG: ${AKS_CL_ARRAY[1]} is: " $AKS_STATUS
     
     AKS_STATUS_ARRAY+=("${AKS_CL_ARRAY[0]},${AKS_CL_ARRAY[1]},$AKS_STATUS")
  done

  clear
  for i in "${AKS_STATUS_ARRAY[@]}"
  do
     AKS_STATUS_LIST+=$i"\n"
  done

  printTable ',' $AKS_STATUS_LIST

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



