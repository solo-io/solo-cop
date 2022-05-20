#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

kubectl apply --context $CLUSTER1 -f $LOCAL_DIR/../../install/http-client/http-client.yaml

kubectl wait deployment/http-client -n http-client --context $CLUSTER1 --for condition=Available=True --timeout 60s