#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Deploy Istio
$LOCAL_DIR/istio/setup-mgmt.sh

# $LOCAL_DIR/istio/setup.sh cluster1
# kubectl apply -f $LOCAL_DIR/istio/strict-mtls.yaml --context $CLUSTER1

# $LOCAL_DIR/istio/setup.sh cluster2
# kubectl apply -f $LOCAL_DIR/istio/strict-mtls.yaml --context $CLUSTER2

# # wait until istiod creates the virtualservices
# kubectl wait deployment --for condition=Available=True -n istio-system --timeout 60s --context $MGMT -l app=istiod

# # Deploy Online Boutique
# $LOCAL_DIR/online-boutique/setup.sh

# # needed for gloo mesh dashboard virtualservice
# kubectl create namespace gloo-mesh --context $MGMT

# # install the gloo mesh dashboard using istio
# $LOCAL_DIR/istio/gloo-mesh-dashboard.sh