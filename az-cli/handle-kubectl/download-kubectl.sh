#!/bin/bash
  

isThereArgs=false
## Parsing the version parameters
while getopts v: option
do
  case "${option}"
  in
    v) VERSION=${OPTARG};;
  esac
  isThereArgs=true
done

if [[ "$isThereArgs" == false ]]; then
	latestUrl=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
	curl -LO "https://storage.googleapis.com/kubernetes-release/release/$latestUrl/bin/linux/amd64/kubectl"
	echo "RESULT: Done..."
        echo ""
        echo "ACTION: chmod kubectl to be executable"
        chmod u+x kubectl
        echo "RESULT: Done..."
        echo "" 
        echo "ACTION: kubectl version is: "
        ./kubectl version | grep "^Client" | awk '{print $5}' | sed 's/GitVersion:"v//g' | sed 's/",//g'
else
	## Setup the compete URL for kubectl download
	url="https://storage.googleapis.com/kubernetes-release/release/v$VERSION/bin/linux/amd64/kubectl"

	## Main
	if curl --output /dev/null --silent --head --fail "$url"; then
  		echo "URL exists: $url"
  		echo ""
  		echo "ACTION: Downloading kubectl binary..."
  		curl -LO $url
  		echo "RESULT: Done..."
  		echo ""
  		echo "ACTION: chmod kubectl to be executable"
  		chmod u+x kubectl
  		echo "RESULT: Done..."
  		echo ""
  		echo "ACTION: kubectl version is: "
  		./kubectl version | grep "^Client" | awk '{print $5}' | sed 's/GitVersion:"v//g' | sed 's/",//g'
	else
  		echo "URL does not exist: $url"
	fi
fi

