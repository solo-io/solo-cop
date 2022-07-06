#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


# Step 1 - Meshctl 
curl -sL https://run.solo.io/meshctl/install | GLOO_MESH_VERSION=${GLOO_MESH_VERSION} sh -

export PATH=$HOME/.gloo-mesh/bin:$PATH


# Step 2 - Install mgmt plane
meshctl install \
  --kubecontext $MGMT \
  --set mgmtClusterName=$MGMT \
  --version $GLOO_MESH_VERSION \
  --license $GLOO_MESH_LICENSE_KEY

# Step 3 - Install Control plane cluster1
meshctl cluster register \
  --kubecontext=$MGMT \
  --version $GLOO_MESH_VERSION \
  --remote-context=$CLUSTER1 \
  $CLUSTER1

# Step 4 - Install Control plane cluster2
meshctl cluster register \
  --kubecontext=$MGMT \
  --version $GLOO_MESH_VERSION \
  --remote-context=$CLUSTER2 \
  $CLUSTER2


# Step 6 - Root Trust Policy
kubectl apply -f $LOCAL_DIR/root-trust-policy.yaml --context $MGMT