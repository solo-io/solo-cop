#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

kubectl apply -n backend-apis-team --context $MGMT -f $LOCAL_DIR/backend-apis-virtual-destinations.yaml

kubectl apply -n web-ui --context $CLUSTER2 -f $LOCAL_DIR/../../install/online-boutique/web-ui-cluster2.yaml

kubectl wait deployment/frontend -n web-ui --context $CLUSTER2 --for condition=Available=True
