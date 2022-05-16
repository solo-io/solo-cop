#!/bin/bash
LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# this assumes istioctl is already installed

cat $LOCAL_DIR/istiooperator-mgmt.yaml | envsubst | istioctl install -y --context mgmt -f -