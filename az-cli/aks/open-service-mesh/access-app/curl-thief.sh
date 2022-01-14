##!/usr/bin/env bash

## Get Thief POD
echo "Get Thief POD"
POD_BOOK_BYER=$(kubectl get pod -n bookthief --no-headers | awk '{print $1}')

## Access Thief POD URL
echo "Access Thief POD URL"
kubectl port-forward $POD_BOOK_BYER -n bookthief 8080:14001 &



