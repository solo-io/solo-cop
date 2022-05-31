#!/bin/bash

set -e

kubectl get VirtualDestination checkout -n backend-apis-team --context $MGMT || fail-message "Could not find the checkout VirtualDestination in the backend-apis-team namespace in the mgmt cluster"
kubectl get VirtualDestination currency -n backend-apis-team --context $MGMT || fail-message "Could not find the currency VirtualDestination in the backend-apis-team namespace in the mgmt cluster"
kubectl get VirtualDestination product-catalog -n backend-apis-team --context $MGMT || fail-message "Could not find the product-catalog VirtualDestination in the backend-apis-team namespace in the mgmt cluster"
kubectl get VirtualDestination shipping -n backend-apis-team --context $MGMT || fail-message "Could not find the shipping VirtualDestination in the backend-apis-team namespace in the mgmt cluster"
kubectl get VirtualDestination cart -n backend-apis-team --context $MGMT || fail-message "Could not find the cart VirtualDestination in the backend-apis-team namespace in the mgmt cluster"

# check for new frontend application
if [ `kubectl get deployment -l checkout-enabled="true" -n web-ui --context $CLUSTER1 | wc -l` -eq "0" ]
then
  fail-message "The frontend deployment has not been updated with the Checkout feature, please deploy it."
fi