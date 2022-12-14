#!/bin/bash
LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# this assumes istioctl is already installed

operator_file=istiooperator-mgmt.yaml
ARCH=$(uname -m) || ARCH="amd64"

if [[ $ARCH == 'arm64' ]]; then
  operator_file=istiooperator-mgmt-arm.yaml
fi

istioctl install --set hub=$ISTIO_IMAGE_REPO --set tag=$ISTIO_IMAGE_TAG -y --context $MGMT -f $LOCAL_DIR/$operator_file

kubectl logs deploy/istio-ingressgateway -n istio-system 

kubectl get pods -A

kubectl get services -A

kubectl describe pods -n istio-system 

kubectl describe services -n istio-system 