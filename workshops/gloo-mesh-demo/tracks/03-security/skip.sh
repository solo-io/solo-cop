#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Step 2 - Backend APIS Zero Trust
kubectl apply -n backend-apis-team --context $MGMT -f $LOCAL_DIR/access-policy.yaml