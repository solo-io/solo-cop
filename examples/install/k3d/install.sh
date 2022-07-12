#!/usr/bin/env bash

export MGMT=mgmt
export CLUSTER1=cluster1
export CLUSTER2=cluster2

this_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $this_dir/lib.sh

k3d registry create registry.localhost --default-network k3d-cluster-network --port 12345 || true

create-k3d-cluster $MGMT $this_dir/$MGMT.yaml
create-k3d-cluster $CLUSTER1 $this_dir/$CLUSTER1.yaml
create-k3d-cluster $CLUSTER2 $this_dir/$CLUSTER2.yaml