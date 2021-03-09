#!/bin/bash

## Get Os Type
echo ""
echo "Get OS Version"
osVersion=$(cat /etc/os-release | grep VERSION_CODENAME | sed 's/VERSION_CODENAME=//g')
echo ""

## Build Options Array
echo ""
echo "Build Options Array"
my_array=($(curl https://packages.microsoft.com/repos/azure-cli/pool/main/a/azure-cli/ | awk '{print $2}' | grep -oP '(?<=">).*?(?=</a>)' | grep $osVersion | sort -r -t "." -n -k1,1 -k2,2 -k3,2))
echo ""

## Declare Options List/Array
echo ""
echo "Declaring Options Array"
declare -a OPTIONS
echo ""

## For Debug
#printf 'array contains %d elements\n' ${#my_array[@]}
#for i in ${!my_array[@]}
#do printf 'my_array[%d] is "%s"\n' $i "${my_array[$i]}"
#done

echo ""
echo "Process Options List"
for i in ${!my_array[@]}
do OPTIONS+=(${my_array[$i]} $i)
done
echo ""

## Define Windows
HEIGHT=30
WIDTH=60
CHOICE_HEIGHT=10
BACKTITLE="AZ-CLI Versions"
TITLE="Choose AZ-CLI Versions"
MENU="Choose one of the following options:"

## Define User Choice
CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)


## Start Dialog Box
for i in ${!CHOICE[@]}
do 
	printf 'CHOICE[%d] is "%s"\n' $i "${CHOICE[$i]}"
	baseUrl="https://packages.microsoft.com/repos/azure-cli/pool/main/a/azure-cli/"
	wget $baseUrl${CHOICE[$i]}
	sudo dpkg -i ${CHOICE[$i]}
	
	rm -rf ${CHOICE[$i]}
done



