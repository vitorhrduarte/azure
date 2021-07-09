#!/bin/bash

my_array=($(az aks list --output json | jq -r '.[] | [.name, .resourceGroup] | @csv'))

declare -a OPTIONS


printf 'array contains %d elements\n' ${#my_array[@]}
for i in ${!my_array[@]}
do printf 'my_array[%d] is "%s"\n' $i "${my_array[$i]}"
done

echo ""

for i in ${!my_array[@]}
do OPTIONS+=(${my_array[$i]} $i)
done

echo ""

HEIGHT=25
WIDTH=100
CHOICE_HEIGHT=15
BACKTITLE="Backtitle here"
TITLE="Title here"
MENU="Choose one of the following options:"


CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

echo ""

optionSplitted=${CHOICE[0]}
my_array_option=($(echo $optionSplitted | tr -d '"' |tr "," "\n"))


echo "Get AKS credentials"
az aks get-credentials --name ${my_array_option[0]} --resource-group ${my_array_option[1]} --overwrite-existing
