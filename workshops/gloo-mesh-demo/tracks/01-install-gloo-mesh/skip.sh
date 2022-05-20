#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


# Step 1 - Meshctl 
curl -sL https://run.solo.io/meshctl/install | GLOO_MESH_VERSION=${GLOO_MESH_VERSION} sh -

export PATH=$HOME/.gloo-mesh/bin:$PATH


# Step 2 - Install mgmt plane
meshctl install \
  --kubecontext $MGMT \
  --set mgmtClusterName=$MGMT \
  --license $GLOO_MESH_LICENSE_KEY \
  --set glooMeshMgmtServer.image.registry=gcr.io/solo-test-236622 \
  --set glooMeshMgmtServer.image.tag=2.1.0-beta2-14-gd556fc77d
# Step 3 - Install Control plane cluster1

meshctl cluster register \
  --kubecontext=$MGMT \
  --remote-context=$CLUSTER1 \
  --version $GLOO_MESH_VERSION \
  $CLUSTER1

# Step 4 - Install Control plane cluster2

meshctl cluster register \
  --kubecontext=$MGMT \
  --remote-context=$CLUSTER2 \
  --version $GLOO_MESH_VERSION \
  $CLUSTER2


# Step 6 - Root Trust Policy

kubectl apply -f $LOCAL_DIR/root-trust-policy.yaml --context $MGMT