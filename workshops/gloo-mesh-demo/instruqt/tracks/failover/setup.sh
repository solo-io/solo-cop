#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

kubectl apply -n web-ui --context $MGMT -f $LOCAL_DIR/backend-apis-virtual-destinations.yaml

kubectl apply -n web-ui --context $CLUSTER2 -f $LOCAL_DIR/../../install/common/online-boutique/web-ui-cluster2.yaml

kubectl wait --for=condition=Ready pod --all -n web-ui --context $CLUSTER2
