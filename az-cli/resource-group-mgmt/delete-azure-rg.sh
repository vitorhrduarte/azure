#!/bin/bash

my_array=($(az group list --output json | jq -r '.[] | [.name, .location] | @csv'))

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

HEIGHT=30
WIDTH=100
CHOICE_HEIGHT=30
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


echo "Stop VMSS Instante"
az group delete --name ${my_array_option[0]} --no-wait --yes --debug



