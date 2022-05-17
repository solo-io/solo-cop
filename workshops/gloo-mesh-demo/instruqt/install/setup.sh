#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Deploy Istio
$LOCAL_DIR/common/install-istio-mgmt.sh

$LOCAL_DIR/common/install-istio.sh cluster1
kubectl apply -f $LOCAL_DIR/common/strict-mtls.yaml --context $CLUSTER1

$LOCAL_DIR/common/install-istio.sh cluster2
kubectl apply -f $LOCAL_DIR/common/strict-mtls.yaml --context $CLUSTER2

# wait until istiod creates the virtualservices
kubectl wait --for=condition=ready pod -l app=istiod -n istio-system --context $MGMT

# Deploy Online Boutique
$LOCAL_DIR/common/install-online-boutique.sh

# needed for gloo mesh dashboard virtualservice
kubectl create namespace gloo-mesh --context $MGMT

# install the gloo mesh dashboard
$LOCAL_DIR/install-gloo-mesh/gloo-mesh-dashboard.sh

# Used for OIDC
GW1=$(kubectl --context ${CLUSTER1} -n istio-gateways get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].*}'):443
export ENDPOINT_HTTPS_GW_CLUSTER1=$GW1