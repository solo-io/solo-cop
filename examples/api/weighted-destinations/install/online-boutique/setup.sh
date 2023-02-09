#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

kubectl apply -n web-ui -f $LOCAL_DIR/web-ui.yaml --context $CLUSTER1
kubectl apply -n backend-apis -f $LOCAL_DIR/backend-apis.yaml --context $CLUSTER1

kubectl apply -n backend-apis -f $LOCAL_DIR/checkout-feature.yaml --context $CLUSTER2

kubectl apply --context $CLUSTER1 -n backend-apis -f $LOCAL_DIR/default-deny.yaml