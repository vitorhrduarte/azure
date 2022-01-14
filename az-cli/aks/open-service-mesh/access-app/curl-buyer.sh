##!/usr/bin/env bash

## Get BookBuyer POD
echo "Get BookBuyer POD"
POD_BOOK_BYER=$(kubectl get pod -n bookbuyer --no-headers | awk '{print $1}')

## Access BookBuyer POD URL
echo "Access BookBuyer POD URL"
kubectl port-forward $POD_BOOK_BYER -n bookbuyer 8080:14001 &



