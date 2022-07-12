#!/usr/bin/env bash

export MGMT=mgmt
export CLUSTER1=cluster1
export CLUSTER2=cluster2

this_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $this_dir/lib.sh

delete-k3d-cluster $MGMT
delete-k3d-cluster $CLUSTER1
delete-k3d-cluster $CLUSTER2