#!/bin/bash

set -e

kubectl get deployment gloo-mesh-mgmt-server -n gloo-mesh --context $MGMT || fail-message "Could not find the gloo-mesh-mgmt-server in the gloo-mesh namespace in the mgmt cluster"

kubectl get deployment gloo-mesh-agent -n gloo-mesh --context $CLUSTER1 || fail-message "Could not find the gloo-mesh-agent deployment in the gloo-mesh namespace in the cluster1"  

kubectl get deployment gloo-mesh-agent -n gloo-mesh --context $CLUSTER2 || fail-message "Could not find the gloo-mesh-agent deployment in the gloo-mesh namespace in the cluster2"

kubectl get RootTrustPolicy root-trust-policy -n gloo-mesh --context $MGMT || fail-message "Could not find the root-trust-policy in the gloo-mesh namespace in the mgmt"