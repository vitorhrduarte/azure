##!/usr/bin/env bash
set -e
. ./params.sh

OSM_CURRENT_LOCAL_VERSION=$(osm version | awk '{print $2}' | sed 's/;//g')

if [[ "$OSM_VERSION" != "$OSM_CURRENT_LOCAL_VERSION" ]]; then
    echo "OSM version not equal"
    echo "Local: " $OSM_CURRENT_LOCAL_VERSION
    echo "New One: " $OSM_VERSION

    CONTINUE="y"

	while [[ "$CONTINUE" == "y" ]]
	do
    	read -p "Change OSM version (y/n/exit): " OSMANSWER

    	if [[ "$OSMANSWER" == "y" ]]  
    	then
            echo "Check if new OSM version is available to download"
            if wget --spider https://github.com/openservicemesh/osm/releases/download/$OSM_VERSION/osm-$OSM_VERSION-linux-amd64.tar.gz 2>/dev/null; then
              echo "File exists"
              echo "Good to go..."
            else
                echo "File does not exist"
                echo "Exiting..."
                exit
            fi

            echo ""
            echo "Apply OSM version..."
			## Linux curl command only
			echo "Install OSM"
			curl -sL "https://github.com/openservicemesh/osm/releases/download/$OSM_VERSION/osm-$OSM_VERSION-linux-amd64.tar.gz" | tar -vxzf -

			## Moving files
			echo ""
			echo "Moving files"
			sudo mv ./linux-amd64/osm /usr/local/bin/osm
			
			## Perfom clean up
			echo ""
			echo "Perfom clean up"
			rm -rf linux-amd64/
			
			## OSM version
			echo""
			echo "OSM version"
			osm version

    	elif [[ "$OSMANSWER" == "n" ]]
    	then
        	echo "Stop and exit..."
            exit           

    	elif [[ "$OSMANSWER" == "exit" ]]
    	then
        	echo "Exiting"
        	CONTINUE="no"
        	exit
    
    	else
        	echo "No valid answer provided..."
        	echo "Please provide a valid answer..."
        	CONTINUE="yes"
    	fi  
    done 
else
    echo "New and local OSM version are the same"
    echo "Nothing to do"
    echo "Exit"
fi
