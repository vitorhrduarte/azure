#!/bin/bash


showHelp() {
cat << EOF  
Usage: 

bash go.sh --help/-h  [for help]
bash go.sh -t/--top <get-top-X-pid - integer> -p/--percentage <percentage-above-cpu-we-want-to-consider integer> -l/--loop <need-endless-loop y/n> 
bash go.sh -t 20 -p 50 -l y

Install Pre-requisites JQ

-h, -help,          --help                  Display help

-t, -top,           --top                   Select the Top X Higher CPU PID consumers (integer value)

-p, -port           --percentage            Percentage that higher than X (integer value) 

-l, -loop,          --loop                  If we want to run once or in a endless loop  (y/n)

EOF
}

options=$(getopt -l "help::,top:,percentage:,loop:" -o "h::o:t:p:l:" -a -- "$@")

eval set -- "$options"

while true
do
case $1 in
-h|--help) 
    showHelp
    exit 0
    ;;  
-t|--top)
    shift
    JIT_OPERATION_TYPE=$1
    ;;  
-p|--percentage)
    shift
    JIT_OPERATION_VM=$1
    ;;  
-l|--loop)
    shift
    JIT_OPERATION_VM_RG=$1
    ;;  
--)
    shift
    break
    exit 0
    ;;
esac
shift
done





PERCENTAGE_ABOVE="1"
LOOP_SLEEP_SEC="2"

declare -a ARR_PS

IFS=$'\n'


ARR_PS=($(ps --no-headers -eo pid,%cpu,comm --sort=-%cpu | awk '$2>='"$PERCENTAGE_ABOVE"'' | awk '{print $1}'))

declare -A ARR_PS_CONT_ID

echo ""
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


i=$(expr ${#ARR_PS_CONT_ID[@]} / 2)

rm -rf out.txt
touch out.txt

l="y"
LOOP_CONTROL="0"

while :;
do
for ((j=0; j<$i; j++))
do
        if [[ "${ARR_PS_CONT_ID[$j,1]}" != "PID_IS_NOT_A_POD" ]];
        then
                if [[ "$LOOP_CONTROL" == "0" ]];
                then
                        crictl pods --id "${ARR_PS_CONT_ID[$j,1]}"  | awk 'NR==1 {print $1" "$2" "$3" "$4" "$5" "$6" "$7}'  | ts '%Y-%m-%d %H:%M:%S' | tee -a out.txt
                        LOOP_CONTROL="1"
                fi 
                crictl pods --id "${ARR_PS_CONT_ID[$j,1]}"  | awk 'NR>1 {print $1" "$2" "$3" "$4" "$5" "$6" "$7}'  | ts '%Y-%m-%d %H:%M:%S' | tee -a out.txt
        fi
done

if [[ "$l" != "y" ]];
then
     exit 1
fi

sleep $LOOP_SLEEP_SEC

done
