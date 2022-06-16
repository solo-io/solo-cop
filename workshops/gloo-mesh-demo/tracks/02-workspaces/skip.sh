#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Step 1 - Workspaces
kubectl apply -n gloo-mesh --context $MGMT -f $LOCAL_DIR/workspaces.yaml

# update the workspace settings that import the gloo-mesh-addons services when they will be deployed
kubectl apply -f $LOCAL_DIR/workspace-settings.yaml --context $MGMT

# Step 5 - Expose Gateway
kubectl apply -f $LOCAL_DIR/virtual-gateway.yaml --context $MGMT
kubectl apply -f $LOCAL_DIR/route-table.yaml --context $MGMT