#!/bin/bash


echo "Reset/Truncate Kube Config"
truncate -s0 ~/.kube/config
