##!/usr/bin/env bash
set -e
. ../params.sh

## Temporarily cp params.sh file to local folder
echo "Temporarily cp params.sh file to local folder"
cp ../params.sh .

## Setup OSM Bins
echo "Setup OSM Bins"
bash ../support-code/install-osm.sh

## Delete params.sh file
echo "Delete params.sh file"
rm -rf params.sh
