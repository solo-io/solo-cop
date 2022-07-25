#!/bin/bash

set -e

kubectl get namespace backend-apis || fail-message "Could not find the backend-apis namespace, was the backend APIs deployed?"

kubectl get namespace web-ui || fail-message "Could not find the web-ui namespace, was the frontend deployed?"

kubectl get Workspace ops-team -n gloo-mesh || fail-message "Could not find the ops-team Workspace in the gloo-mesh namespace."

kubectl get WorkspaceSettings dev-team -n dev-team || fail-message "Could not find the dev-team WorkspaceSettings in the dev-team namespace."

kubectl get WorkspaceSettings ops-team -n dev-team || fail-message "Could not find the ops-team WorkspaceSettings in the ops-team namespace."

kubectl get RouteTable ingress -n ops-team || fail-message "Could not find the RouteTable ingress in the ops-team namespace."

kubectl get RouteTable frontend -n dev-team || fail-message "Could not find the RouteTable frontend in the dev-team namespace."

kubectl get VirtualGateway -l ingress=ssl-enabled -n ops-team || fail-message "Could not find the VirtualGateway with ssl enabled in the ops-team namespace."
