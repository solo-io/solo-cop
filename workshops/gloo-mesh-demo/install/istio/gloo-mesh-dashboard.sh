#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# expose gloo mesh dashboard
kubectl apply -f $LOCAL_DIR/gateway.yaml --context $MGMT