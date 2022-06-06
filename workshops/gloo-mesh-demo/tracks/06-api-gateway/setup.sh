#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# install keycloak
$LOCAL_DIR/../../install/keycloak/setup.sh

$LOCAL_DIR/../../install/gloo-mesh-addons/setup.sh

# update the workspace settings to import the gloo-mesh-addons services
kubectl apply -f $LOCAL_DIR/workspace-settings.yaml --context $MGMT

# remove the load generator so we dont disturb rate limiting
kubectl delete deployment loadgenerator -n web-ui --context $CLUSTER1