#!/bin/bash
LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [ -z "$1" ]
then 
    echo 'cluster name required!' 
    return 0
fi 

# this assumes istioctl is already installed

# Install cluster
export CLUSTER_NAME=$1
export TRUST_DOMAIN=$CLUSTER_NAME.solo.io
export NETWORK=$CLUSTER_NAME-network

operator_file=istiooperator-$CLUSTER_NAME.yaml
ARCH=$(uname -m) || ARCH="amd64"

if [[ $ARCH == 'arm64' ]]; then
  operator_file=istiooperator-arm-$CLUSTER_NAME.yaml
fi

kubectl create namespace istio-gateways --context $CLUSTER_NAME
istioctl install --set hub=$ISTIO_IMAGE_REPO --set tag=$ISTIO_IMAGE_TAG  -y --context $CLUSTER_NAME -f $LOCAL_DIR/$operator_file