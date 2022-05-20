#!/bin/bash
LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# this assumes istioctl is already installed

operator_file=istiooperator-mgmt.yaml
ARCH=$(uname -m) || ARCH="amd64"

if [[ $ARCH == 'arm64' ]]; then
  operator_file=istiooperator-mgmt-arm.yaml
fi

cat $LOCAL_DIR/$operator_file | envsubst | istioctl install -y --context $MGMT -f -