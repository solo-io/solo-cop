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

kubectl create namespace istio-gateways --context $CLUSTER_NAME

cat $LOCAL_DIR/istiooperator.yaml | envsubst | istioctl install -y --context $CLUSTER_NAME -f -