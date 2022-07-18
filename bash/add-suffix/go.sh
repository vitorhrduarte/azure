 ##!/usr/bin/env bash

showHelp() {
cat << EOF  
Usage: 

bash go.sh --help/-h  [for help]
bash go.sh -o/--origin <origin-file> -d/--destination <destination-file> -s/--suffix <suffix-to-add>

<>
Add to each line the desired suffix
<>

-h, -help,          --help                  Display help

-o, -origin,        --origin                Set origin file

-d, -destination,   --destination           Set destination file            

-s, -suffix,        --suffix                Suffix to add to each origin file

EOF
}

options=$(getopt -l "help::,origin:,destination:,suffix:" -o "h::o:d:s:" -a -- "$@")

eval set -- "$options"

while true
do
case $1 in
-h|--help) 
    showHelp
    exit 0
    ;;  
-o|--origin)
    shift
    ORIGIN_FILE=$1
    ;;  
-d|--destination)
    shift
    DESTINATION_FILE=$1
    ;;  
-s|--suffix)
    shift
    SUFFIX=$1
    ;;  
--)
    shift
    break
    exit 0    
    ;;  
esac
shift
done


if [ -f "$ORIGIN_FILE" ];
then
  if [ ! -z "$SUFFIX" ];
  then
    rm -rf $DESTINATION_FILE
    cat $ORIGIN_FILE | awk -v suf="$SUFFIX" '{print $0""suf}' >> $DESTINATION_FILE
    rm -rf $ORIGIN_FILE
  else
    echo "Suffix is empty!!!"
    exit
  fi
else
  echo "Original File dont exist!!!"
  exit
fi
