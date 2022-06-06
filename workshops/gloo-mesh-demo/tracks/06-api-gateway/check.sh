#!/bin/bash

set -e

kubectl get WAFPolicy log4jshell -n web-team --context $MGMT || fail-message "Could not find the failover WAFPolicy in the web-team namespace in the mgmt cluster"
kubectl get ExtAuthPolicy frontend -n web-team --context $MGMT || fail-message "Could not find the frontend ExtAuthPolicy in the web-team namespace in the mgmt cluster"
kubectl get RateLimitPolicy rate-limit-policy -n web-team --context $MGMT || fail-message "Could not find the frontend RateLimitPolicy in the web-team namespace in the mgmt cluster"
