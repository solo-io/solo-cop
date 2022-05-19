#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

kubectl create namespace keycloak --context $CLUSTER1

kubectl apply --context $CLUSTER1 -n keycloak -f $LOCAL_DIR/keycloak.yaml
sleep 2
kubectl wait --for=condition=ready pod -l app=keycloak -n keycloak --timeout 60s --context $CLUSTER1

POD_NAME=$(kubectl get pods -n keycloak -l app=keycloak --context $CLUSTER1 -o json | jq -r '.items[0].metadata.name')
# Get Keycloak URL and token
export ENDPOINT_KEYCLOAK=$EXTERNAL_IP:$(kubectl --context ${MGMT} -n keycloak get svc keycloak -o jsonpath='{.spec.ports[?(@.port==8080)].nodePort}')
export HOST_KEYCLOAK=$(echo ${ENDPOINT_KEYCLOAK} | cut -d: -f1)
export PORT_KEYCLOAK=$(echo ${ENDPOINT_KEYCLOAK} | cut -d: -f2)
export KEYCLOAK_URL=http://${ENDPOINT_KEYCLOAK}/auth
echo "Keycloak URL: $KEYCLOAK_URL"
kubectl apply --context $CLUSTER1 -f $LOCAL_DIR/keycloak-setup-pod.yaml
kubectl wait --for=condition=ready pod -l app=keycloak-setup -n keycloak --context $CLUSTER1

kubectl --context $CLUSTER1 -n keycloak cp $LOCAL_DIR/gen-clientid.sh keycloak-setup:/tmp/gen-clientid.sh
kubectl exec --context $CLUSTER1 -n keycloak -it keycloak-setup -- env KEYCLOAK_URL=$KEYCLOAK_URL ENDPOINT_HTTPS_GW_CLUSTER1_EXT=$ENDPOINT_HTTPS_GW_CLUSTER1_EXT /tmp/gen-clientid.sh