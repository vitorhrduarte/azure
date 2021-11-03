#!/bin/bash


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


function getVmss()
{
AKS_ARRAY=($(az aks list --output json | jq -r ".[] | [ .name, .resourceGroup,.nodeResourceGroup ] | @csv"))

declare -a AKS_STATUS_ARRAY
AKS_VMSS_ARRAY=("Name,npK8S,RG,AKSStatus,AKSName,AKSInfraRG,VMSSName,VMSSStatus")

for vmss in "${AKS_ARRAY[@]}"; do
     AKS_CL_ARRAY=($(echo $vmss | tr -d '"' |tr "," "\n"))
     
     AKS_VMSS_STATUS_ARRAY=($(az aks nodepool list --cluster-name ${AKS_CL_ARRAY[0]} --resource-group ${AKS_CL_ARRAY[1]} --output json 2>/dev/null | jq -r ".[] | [ .name, .orchestratorVersion, .resourceGroup, .powerState.code ] | @csv"))

    for i in "${AKS_VMSS_STATUS_ARRAY[@]}"; do
       AKS_VMSS=($(echo $i | tr -d '"' |tr "," "\n"))
       
       AKS_VMSS_INFO=$(az aks show --name ${AKS_CL_ARRAY[0]} --resource-group ${AKS_VMSS[2]} --output json  2>/dev/null | jq -r ".nodeResourceGroup")
       
       AKS_VMSS_DETAILS=$(az vmss list  --resource-group $AKS_VMSS_INFO  --output json | jq -r ".[] | select( .name | contains(\"${AKS_VMSS[0]}\")) | [ .name] | @tsv")

       AKS_INFRA_RG_UPPER=$(echo ${AKS_CL_ARRAY[2]} | tr '[:lower:]' '[:upper:]')

       AKS_NP_STATUS=$(az vmss get-instance-view --name $AKS_VMSS_DETAILS --resource-group $AKS_INFRA_RG_UPPER --instance-id "*" --output json | jq -r ".[] | [ .statuses[1].displayStatus ] | @tsv" | uniq)
      
       if [ "$(az vmss get-instance-view --name $AKS_VMSS_DETAILS --resource-group $AKS_INFRA_RG_UPPER --instance-id "*" --output json | jq -r ".[] | [ .statuses[1].displayStatus ] | @tsv")" = "" ]; 
       then 
         AKS_NP_STATUS="N/A" 
       else 
         AKS_NP_STATUS=$(az vmss get-instance-view --name $AKS_VMSS_DETAILS --resource-group $AKS_INFRA_RG_UPPER --instance-id "*"  --output json | jq -r ".[] | [ .statuses[1].displayStatus ] | @tsv" | uniq)
       fi

       AKS_NP_STATUS=$(echo ${AKS_NP_STATUS//[[:blank:]]/})

       AKS_VMSS_ARRAY+=($(echo $i),${AKS_CL_ARRAY[0]},${AKS_CL_ARRAY[2]},$AKS_VMSS_DETAILS,$AKS_NP_STATUS)
    done
done

clear

AKS_VMSS_LIST=()

for i in "${AKS_VMSS_ARRAY[@]}"
do
   AKS_VMSS_LIST+=$i"\n"
done

printTable ',' $AKS_VMSS_LIST

}

getVmss

CONTINUE="yes"

while [[ "$CONTINUE" == "yes" ]]
do
    read -p "start/stop VMSS or exit: " VMSSANSWER

	if [[ "$VMSSANSWER" == "start" ]]  
	then
		read -p "AKS VMSS Name: " VMSSNAME
		read -p "AKS VMSS Infra RG: " VMSSINFRARG

		echo "Starting VMSS..."
		az vmss start --name $VMSSNAME --resource-group $VMSSINFRARG
    
        getVmss

    elif [[ "$VMSSANSWER" == "stop" ]]
	then
   		read -p "AKS VMSS Name: " VMSSNAME
   		read -p "AKS VMSS Infra RG: " VMSSINFRARG

   		echo "Stoping VMSS..."
   		az vmss stop --name $VMSSNAME --resource-group $VMSSINFRARG 
	
        getVmss

    elif [[ "$VMSSANSWER" == "exit" ]]
	then
   		echo "Exiting"
        CONTINUE="no"
   		exit
    
    else
   		echo "No valid answer provided..."
        echo "Please provide a valid answer..."
        CONTINUE="yes"
    fi
done

