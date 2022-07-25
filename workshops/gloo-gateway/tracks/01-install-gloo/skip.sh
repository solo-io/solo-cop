#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


# Step 1 - Meshctl 
curl -sL https://run.solo.io/meshctl/install | GLOO_MESH_VERSION=${GLOO_PLATFORM_VERSION} sh -

export PATH=$HOME/.gloo-mesh/bin:$PATH

# Step 2 - Install gloo platform
meshctl install \
  --license $GLOO_GATEWAY_LICENSE_KEY \
  --register \
  --version $GLOO_PLATFORM_VERSION

# Install gloo gateway
kubectl create namespace gloo-gateway
kubectl label namespace gloo-gateway istio-injection=enabled
istioctl install -y --set hub=$ISTIO_IMAGE_REPO --set tag=$ISTIO_IMAGE_TAG -f $LOCAL_DIR/../../install/gloo-gateway/install.yaml

# Install addons
kubectl create namespace dev-team
kubectl create namespace ops-team
kubectl create namespace gloo-gateway-addons
kubectl label namespace gloo-gateway-addons istio-injection=enabled

helm repo add gloo-mesh-agent https://storage.googleapis.com/gloo-mesh-enterprise/gloo-mesh-agent
helm repo update

helm upgrade --install gloo-gateway-addons gloo-mesh-agent/gloo-mesh-agent \
  --namespace gloo-gateway-addons \
  --set glooMeshAgent.enabled=false \
  --set rate-limiter.enabled=true \
  --set ext-auth-service.enabled=true \
  --version $GLOO_PLATFORM_VERSION

kubectl apply -f $LOCAL_DIR/../../install/gloo-gateway/addons-servers.yaml