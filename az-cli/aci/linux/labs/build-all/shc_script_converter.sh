#!/bin/bash

## Script to convert the base lab scripts to binaries

SHC_STATUS=$(which shc > /dev/null; echo $?)
if [ $SHC_STATUS -ne 0 ]
then
    echo -e "\nError: missing shc binary...\n"
    exit 4
fi

ACILABS_SCRIPTS="$(ls ./acilabs_scripts/)"
if [ -z "$ACILABS_SCRIPTS" ]
then
    echo -e "Error: missing acilabs scripts...\n"
    exit 5
fi

function convert_to_binary() {
    SCRIPT_NAME="$1"
    BINARY_NAME="$(echo "$SCRIPT_NAME" | sed 's/.sh//')"
    shc -f ./acilabs_scripts/${SCRIPT_NAME} -r -o ./acilabs_binaries/${BINARY_NAME}
    rm -f ./acilabs_scripts/${SCRIPT_NAME}.x.c > /dev/null 2>&1
}

for FILE in $(echo "$ACILABS_SCRIPTS")
do
    convert_to_binary $FILE
done

exit 0
