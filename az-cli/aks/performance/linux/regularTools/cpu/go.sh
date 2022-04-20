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



ps -eo pid,%cpu,comm --sort=-%cpu | awk '$2>=3.2' | awk '{print $1}' | xargs -I '{}' bash -c "pstree -als {}" | grep containerd-shim | awk '{print $5}' | uniq | xargs -I '{}' bash -c "crictl ps --no-trunc -p {} && echo "" && crictl pods --id {}"
