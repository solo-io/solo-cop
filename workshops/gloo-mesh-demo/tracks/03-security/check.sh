#!/bin/bash

set -e

kubectl get AccessPolicy frontend-api-access -n backend-apis-team --context $MGMT || fail-message "Could not find the frontend-api-access AccessPolicy in the backend-apis-team namespace in the mgmt cluster"

kubectl get AccessPolicy in-namespace-access -n backend-apis-team --context $MGMT || fail-message "Could not find the in-namespace-access AccessPolicy in the backend-apis-team namespace in the mgmt cluster"
