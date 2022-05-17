#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Step 1 - VirtualDestinations

kubectl apply -n backend-apis-team --context $MGMT -f $LOCAL_DIR/virtual-destinations.yaml --context $MGMT

# Step 2 - Update frontend
kubectl apply -n web-ui --context $CLUSTER1 -f $LOCAL_DIR/frontend-global-hosts.yaml

kubectl wait pod -n web-ui --context $CLUSTER1 --for=condition=Ready --all