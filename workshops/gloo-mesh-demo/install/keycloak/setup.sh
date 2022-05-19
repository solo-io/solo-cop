#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

kubectl create namespace keycloak --context $CLUSTER1

kubectl apply --context $CLUSTER1 -n keycloak -f $LOCAL_DIR/keycloak.yaml
sleep 2
kubectl wait deployment --for condition=Available=True -n keycloak --timeout 60s --context $CLUSTER1 --all

POD_NAME=$(kubectl get pods -n keycloak -l app=keycloak --context $CLUSTER1 -o json | jq -r '.items[0].metadata.name')

if [ -z "$EXTERNAL_IP" ]
then
  # Running locally
  export KEYCLOAK_URL=http://$(kubectl --context ${CLUSTER1} -n keycloak get service keycloak -o jsonpath='{.status.loadBalancer.ingress[0].*}'):9000/auth
  echo "Using LOCAL Keycloak URL: $KEYCLOAK_URL"
else
  
  # we are running in instruqt
  export ENDPOINT_KEYCLOAK=$EXTERNAL_IP:$(kubectl --context ${CLUSTER1} -n keycloak get svc keycloak -o jsonpath='{.spec.ports[?(@.port==9000)].nodePort}')
  export KEYCLOAK_URL=http://${ENDPOINT_KEYCLOAK}/auth
  echo "Using Instruqt Keycloak URL: $KEYCLOAK_URL"
fi

echo "Keycloak URL: $KEYCLOAK_URL"
kubectl apply --context $CLUSTER1 -f $LOCAL_DIR/keycloak-setup-pod.yaml
kubectl wait --for=condition=ready pod -l app=keycloak-setup -n keycloak --context $CLUSTER1

kubectl --context $CLUSTER1 -n keycloak cp $LOCAL_DIR/gen-clientid.sh keycloak-setup:/tmp/gen-clientid.sh

echo "Keycloak authorized endpoint: $ENDPOINT_HTTPS_GW_CLUSTER1_EXT"
kubectl exec --context $CLUSTER1 -n keycloak -it keycloak-setup -- env KEYCLOAK_URL=$KEYCLOAK_URL /tmp/gen-clientid.sh $ENDPOINT_HTTPS_GW_CLUSTER1_EXT