#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Step 1 - Enable Multi Cluster Frontend
kubectl apply -n web-team --context $MGMT -f $LOCAL_DIR/virtual-destination.yaml

kubectl apply -n web-team --context $MGMT -f $LOCAL_DIR/route-table.yaml

# Step 3 - Failover POlicy

kubectl apply -n web-team --context $MGMT -f $LOCAL_DIR/failover-policy.yaml

# Step 4 - Outlier Detection Policy 

kubectl apply -n web-team --context $MGMT -f $LOCAL_DIR/outlier-detection-policy.yaml