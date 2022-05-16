#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Step 1 - Enable Multi Cluster Frontend
kubectl apply -n web-team --context $MGMT -f /workshop/tracks/failover/virtual-destination.yaml

kubectl apply -n web-team --context $MGMT -f /workshop/tracks/failover/route-table.yaml