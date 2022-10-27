#!/bin/bash


###################################
##  Vars
###################################

## Path to the hosts file
ETC_HOSTS=/etc/hosts


###################################
##  Functions
###################################


showHelp() {
cat << EOF  
Usage: 

bash change-hosts-file.sh --help/-h  [for help]
bash change-hosts-file.sh -o/--operation <add remove list> -f/--file <local-path-file-name>

Example: bash edit-hosts-file.sh -o list -f input-servers.txt

-h, -help,          --help                  Display help

-o, -operation,     --operation             Set operation type: add, remove or list /etc/hosts file

-f, -file,          --file                  Name of the list file with data in format: ip name 

EOF
}


options=$(getopt -l "help::,operation:,file:" -o "h::o:f:" -a -- "$@")

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
    OPERATION_TYPE=$1
    ;;  
-f|--file)
    shift
    OPERATION_FILE_NAME=$1
    ;;  
--)
    shift
    break
    exit 0    
    ;;  
esac
shift
done


function remove() {
    # IP to add/remove.
    IP=$1
    # Hostname to add/remove.
    HOSTNAME=$2
    HOSTS_LINE="$IP[[:space:]]$HOSTNAME"

    if [ -n "$(grep -P $HOSTS_LINE $ETC_HOSTS)" ]
    then
        echo "$HOSTS_LINE Found in your $ETC_HOSTS, Removing now...";
        sudo sed -i".bak" "/$HOSTS_LINE/d" $ETC_HOSTS
    else
        echo "$HOSTS_LINE was not found in your $ETC_HOSTS";
    fi
}

function add() {
    IP=$1
    HOSTNAME=$2
    HOSTS_LINE="$IP[[:space:]]$HOSTNAME"

    line_content=$( printf "%s\t%s\n" "$IP" "$HOSTNAME" )
    
    if [ -n "$(grep -P $HOSTS_LINE $ETC_HOSTS)" ]
        then
            echo "$line_content already exists : $(grep $HOSTNAME $ETC_HOSTS)"
        else
            echo "Adding $line_content to your $ETC_HOSTS";
            sudo -- sh -c -e "echo $line_content >> /etc/hosts";

            if [ -n "$(grep -P $HOSTNAME $ETC_HOSTS)" ]
                then
                    echo "$line_content was added succesfully";
                else
                    echo "Failed to Add $line_content, Try again!";
            fi
    fi
}




#####################
## Core
#####################


## Check if option belong to the authorized ones (below in array)
CONTROL_RESULT="0"
OPTIONS_ARRAY=("add" "remove" "list")

for i in "${OPTIONS_ARRAY[@]}"
do
    if [ "$i" == "$OPERATION_TYPE" ] ; then
        echo "Found"
	CONTROL_RESULT="1"
    fi
done


## Check if input file exits
if [ -f "$OPERATION_FILE_NAME" ]; 
then
   echo "File exist"
else
   if [[ "$CONTROL_RESULT" == "1" ]]
   then
      echo "Just list contents..."	   
   else
     echo "Exiting, file not found"	   
     echo "Exiting...."
     exit
   fi
fi


echo ""
echo ""
echo "Good to Go!!!"
echo ""
echo ""


if [[ "$CONTROL_RESULT" == "1" ]]
then
  if [[ "$OPERATION_TYPE" == "add" ]]
  then
    while IFS= read -r file; do
    add $file
    done < "$OPERATION_FILE_NAME"
  elif [[ "$OPERATION_TYPE" == "remove" ]]
  then
    while IFS= read -r file; do
    remove $file
    done < "$OPERATION_FILE_NAME"
  elif [[ "$OPERATION_TYPE" == "list" ]]
  then	  
    cat $ETC_HOSTS 
  else
    echo "Operation not allowed: $OPERATION_TYPE"
    echo ""
    exit
  fi
fi


