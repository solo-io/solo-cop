#!/bin/bash

set -e

kubectl get VirtualDestination checkout -n backend-apis-team --context $MGMT || fail-message "Could not find the checkout VirtualDestination in the backend-apis-team namespace in the mgmt cluster"
kubectl get VirtualDestination currency -n backend-apis-team --context $MGMT || fail-message "Could not find the currency VirtualDestination in the backend-apis-team namespace in the mgmt cluster"
kubectl get VirtualDestination product-catalog -n backend-apis-team --context $MGMT || fail-message "Could not find the product-catalog VirtualDestination in the backend-apis-team namespace in the mgmt cluster"
kubectl get VirtualDestination shipping -n backend-apis-team --context $MGMT || fail-message "Could not find the shipping VirtualDestination in the backend-apis-team namespace in the mgmt cluster"
kubectl get VirtualDestination cart -n backend-apis-team --context $MGMT || fail-message "Could not find the cart VirtualDestination in the backend-apis-team namespace in the mgmt cluster"