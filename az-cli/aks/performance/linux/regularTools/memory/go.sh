#!/bin/bash


## Hard code VARS
## Number os Seconds that we wait for each repetition of the loop
LOOP_SLEEP_SEC="5"
OUTPUT_FILE_NAME="out.txt"

## Functions
showHelp() {
cat << EOF  
Usage: 

bash go.sh --help/-h  [for help]
bash go.sh -p/--percentage <percentage-above-mem-we-want-to-consider integer> -l/--loop <need-endless-loop y/n> 
bash go.sh -p 50 -l y

Install Pre-requisites ts (apt install moreutils) to add timestamp to every line

-h, -help,          --help                  Display help

-p, -port           --percentage            Percentage that higher than X (integer value) 

-l, -loop,          --loop                  If we want to run once or in a endless loop  (y/n)

EOF
}

options=$(getopt -l "help::,percentage:,loop:" -o "h:::p:l:" -a -- "$@")

eval set -- "$options"

while true
do
case $1 in
-h|--help) 
    showHelp
    exit 0
    ;;  
-p|--percentage)
    shift
    PERCENTAGE_MEM=$1
    ;;  
-l|--loop)
    shift
    DO_LOOP=$1
    ;;  
--)
    shift
    break
    exit 0
    ;;
esac
shift
done



rm -rf $OUTPUT_FILE_NAME
touch $OUTPUT_FILE_NAME
LOOP_CONTROL="0"

## Get All PID that are above the PERCENTAGE_MEM 
while :;
  declare -a ARR_PS=()
  IFS=$'\n'
  
  ARR_PS=($(ps --no-headers -eo pid,%mem,comm --sort=-%mem | awk '$2>='"$PERCENTAGE_MEM"'' | awk '{print $1}'))

  ## For each of those PID, get the one that are pods 
  declare -A ARR_PS_CONT_ID=()

  j=0
  for i in "${ARR_PS[@]}"
  do
    TEMP_POD_ID=$(pstree -als $i | grep containerd-shim | awk '{print $5}'  | uniq)
  
    if [[ -z $TEMP_POD_ID ]];
    then
      ARR_PS_CONT_ID[$j,0]="$i"
      ARR_PS_CONT_ID[$j,1]="PID_IS_NOT_A_POD"
    else
      ARR_PS_CONT_ID[$j,0]="$i"
      ARR_PS_CONT_ID[$j,1]="$TEMP_POD_ID"
    fi
  
    j=$((j+1))
  done

  ## For each of those pods get the details
  i=$(expr ${#ARR_PS_CONT_ID[@]} / 2)
  j=0
  
  do
    for ((j=0; j<$i; j++))
    do
     if [[ "${ARR_PS_CONT_ID[$j,1]}" != "PID_IS_NOT_A_POD" ]];
     then
       if [[ "$LOOP_CONTROL" == "0" ]];
       then
         crictl pods --id "${ARR_PS_CONT_ID[$j,1]}"  | awk 'NR==1 {print $1" "$2" "$3" "$4" "$5" "$6" "$7}'  | ts '%Y-%m-%d %H:%M:%S' | tee -a $OUTPUT_FILE_NAME
         LOOP_CONTROL="1"
       fi 
       
       crictl pods --id "${ARR_PS_CONT_ID[$j,1]}"  | awk 'NR>1 {print $1" "$2" "$3" "$4" "$5" "$6" "$7}'  | ts '%Y-%m-%d %H:%M:%S' | tee -a $OUTPUT_FILE_NAME
     fi
    done

    if [[ "$DO_LOOP" != "y" ]];
    then
     exit 1
    fi
  
    sleep $LOOP_SLEEP_SEC
done



