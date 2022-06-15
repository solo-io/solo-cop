#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Step 1 - VirtualDestinations

kubectl apply -n backend-apis-team --context $MGMT -f $LOCAL_DIR/virtual-destinations.yaml --context $MGMT
