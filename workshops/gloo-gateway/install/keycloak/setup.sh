#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

kubectl create namespace keycloak

kubectl apply -n keycloak -f $LOCAL_DIR/keycloak.yaml
kubectl wait deployment --for condition=Available=True -n keycloak --timeout 60s --all --timeout 180s

# wait for service load balancer
until kubectl get service/keycloak -n keycloak --output=jsonpath='{.status.loadBalancer}' | grep "ingress"; do : ; done

POD_NAME=$(kubectl get pods -n keycloak -l app=keycloak -o json | jq -r '.items[0].metadata.name')

kubectl apply -f $LOCAL_DIR/keycloak-setup-pod.yaml
kubectl wait --for=condition=ready pod -l app=keycloak-setup -n keycloak --timeout 60s

kubectl -n keycloak cp $LOCAL_DIR/gen-clientid.sh keycloak-setup:/tmp/gen-clientid.sh

echo "Keycloak authorized endpoint: $GLOO_GATEWAY"
kubectl exec -n keycloak -it keycloak-setup -- /tmp/gen-clientid.sh $GLOO_GATEWAY

export KEYCLOAK_CLIENTID=$(kubectl get configmap -n gloo-mesh keycloak-info -o json | jq -r '.data."client-id"')
echo "ClientId: $KEYCLOAK_CLIENTID"