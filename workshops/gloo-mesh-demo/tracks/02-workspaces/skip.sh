#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Step 1 - Workspaces
kubectl apply -n gloo-mesh --context $MGMT -f $LOCAL_DIR/workspaces.yaml

# Step 2 - Ops team
kubectl apply -n ops-team --context $MGMT -f $LOCAL_DIR/workspace-settings-ops-team.yaml

# Step 3 - Web Team
kubectl apply -n web-team --context $MGMT -f $LOCAL_DIR/workspace-settings-web-team.yaml

# Step 4 - Backend Team
kubectl apply -n backend-apis-team --context $MGMT -f $LOCAL_DIR/workspace-settings-backend-apis-team.yaml

# Step 5 - Expose Gateway
kubectl apply -f $LOCAL_DIR/virtual-gateway.yaml --context $MGMT
kubectl apply -f $LOCAL_DIR/route-table.yaml --context $MGMT