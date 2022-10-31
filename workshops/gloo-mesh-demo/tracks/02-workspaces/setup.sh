#!/bin/bash

# create ssl certificate for https traffic
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
   -keyout tls.key -out tls.crt -subj "/CN=*"

kubectl --context ${CLUSTER1} -n istio-ingress create secret generic tls-secret \
--from-file=tls.key=tls.key \
--from-file=tls.crt=tls.crt

rm tls.crt
rm tls.key

# make sure root trust policy is good to go
sleep 5

kubectl wait deployment -n web-ui --context $CLUSTER1 --for condition=Available=True --all --timeout 60s
kubectl wait deployment -n backend-apis --context $CLUSTER1 --for condition=Available=True --all --timeout 60s
kubectl wait deployment -n backend-apis --context $CLUSTER2 --for condition=Available=True --all --timeout 60s