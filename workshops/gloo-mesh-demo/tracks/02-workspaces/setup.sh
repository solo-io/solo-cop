#!/bin/bash

# create ssl certificate for https traffic
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
   -keyout tls.key -out tls.crt -subj "/CN=*"

kubectl --context ${CLUSTER1} -n istio-gateways create secret generic tls-secret \
--from-file=tls.key=tls.key \
--from-file=tls.crt=tls.crt

rm tls.crt
rm tls.key

# make sure root trust policy is good to go
sleep 5

kubectl wait --for=condition=Ready pod --all -n web-ui --context $CLUSTER1
kubectl wait --for=condition=Ready pod --all -n backend-apis --context $CLUSTER1
kubectl wait --for=condition=Ready pod --all -n backend-apis --context $CLUSTER2