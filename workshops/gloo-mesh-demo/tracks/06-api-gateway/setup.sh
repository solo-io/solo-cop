#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# install keycloak
$LOCAL_DIR/../../install/keycloak/setup.sh

$LOCAL_DIR/../../install/gloo-mesh-addons/setup.sh

# remove the load generator so we dont disturb rate limiting
kubectl delete deployment loadgenerator -n web-ui --context $CLUSTER1

kubectl apply -f $LOCAL_DIR/gloo-mesh-addons-servers.yaml --context $MGMT