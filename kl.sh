#!/bin/bash

comp=$1
if [ -z "$comp" ]; then
    echo "Usage: $0 <component>"
    exit 1
fi

# Search for the newest pod in the list, and return the log stream
kubectl get pods -l component=$comp -o=custom-columns='creationTimestamp:.metadata.creationTimestamp,name:.metadata.name' --no-headers | sort -r | head -n 1 | cut -d " " -f 2- | xargs kubectl logs -c $comp -f
