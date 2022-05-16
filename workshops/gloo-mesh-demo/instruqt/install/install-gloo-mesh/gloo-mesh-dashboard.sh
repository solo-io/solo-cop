#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# expose gloo mesh dashboard
kubectl apply -f $SCRIPT_DIR/install-gloo-mesh/gateway.yaml