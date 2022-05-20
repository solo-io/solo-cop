#!/bin/bash

set -e

kubectl get workspace ops-team -n gloo-mesh --context $MGMT || fail-message "Could not find the ops-team Workspace in the gloo-mesh namespace in the mgmt cluster"

kubectl get workspace web-team -n gloo-mesh --context $MGMT || fail-message "Could not find the ops-team Workspace in the gloo-mesh namespace in the mgmt cluster"

kubectl get workspace backend-apis-team -n gloo-mesh --context $MGMT || fail-message "Could not find the ops-team Workspace in the gloo-mesh namespace in the mgmt cluster"

# Workspace Settings
kubectl get workspacesettings ops-team -n ops-team --context $MGMT || fail-message "Could not find the ops-team WorkspaceSettings in the ops-team namespace in the mgmt cluster"

kubectl get workspacesettings web-team -n web-team --context $MGMT || fail-message "Could not find the web-team WorkspaceSettings in the web-team namespace in the mgmt cluster"

kubectl get workspacesettings backend-apis-team -n backend-apis-team --context $MGMT || fail-message "Could not find the backend-apis-team WorkspaceSettings in the backend-apis-team namespace in the mgmt cluster"

# Virtual Gateway and RouteTable
kubectl get VirtualGateway north-south-gw -n ops-team --context $MGMT || fail-message "Could not find the north-south-gw VirtualGateway in the ops-team namespace in the mgmt cluster"

kubectl get RouteTable frontend -n web-team --context $MGMT || fail-message "Could not find the frontend RouteTable in the web-team namespace in the mgmt cluster"
