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



AKS_ARRAY=($(az aks list --output json | jq -r ".[] | [ .name, .location, .resourceGroup, .kubernetesVersion, .provisioningState, .azurePortalFqdn ] | @csv"))

declare -a AKS_STATUS_ARRAY
AKS_STATUS_ARRAY=("ClusterName,Location,RG,K8SVersion,Status,FQDN")

for akscl in "${AKS_ARRAY[@]}"; do
     AKS_CL_ARRAY=($(echo $akscl | tr -d '"' |tr "," "\n"))
     
     ## Get Cluster Status
     AKS_STATUS=$(az aks show --name ${AKS_CL_ARRAY[0]} --resource-group ${AKS_CL_ARRAY[2]} -o json | jq -r '.powerState.code')

     AKS_STATUS_ARRAY+=("${AKS_CL_ARRAY[0]},${AKS_CL_ARRAY[1]},${AKS_CL_ARRAY[2]},${AKS_CL_ARRAY[3]},$AKS_STATUS,${AKS_CL_ARRAY[5]}")
done

clear
for i in "${AKS_STATUS_ARRAY[@]}"
do
   AKS_STATUS_LIST+=$i"\n"
done

printTable ',' $AKS_STATUS_LIST





