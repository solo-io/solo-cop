#!/bin/bash

set -e

kubectl get FailoverPolicy failover -n web-team --context $MGMT || fail-message "Could not find the failover FailoverPolicy in the web-team namespace in the mgmt cluster"
kubectl get OutlierDetectionPolicy outlier-detection -n web-team --context $MGMT || fail-message "Could not find the outlier-detection OutlierDetectionPolicy in the web-team namespace in the mgmt cluster"
kubectl get VirtualDestination frontend -n web-team --context $MGMT || fail-message "Could not find the frontend VirtualDestination in the web-team namespace in the mgmt cluster"

# check for new frontend application
if [ `kubectl get RouteTable -l lab=failover -n web-team --context $MGMT | wc -l` -eq "0" ]
then
  fail-message "The frontend RouteTable has not been updated to route to the VirtualDestination."
fi