#!/bin/bash
export GLOO_PLATFORM_VERSION=v2.3.0
export ISTIO_REVISION=1-16

# K8s Contexts
export MGMT=mgmt
export CLUSTER1=cluster1
export CLUSTER2=cluster2

# Install Gloo Mesh

helm upgrade --install gloo-platform-crds gloo-platform/gloo-platform-crds \
  --version=$GLOO_PLATFORM_VERSION \
  --devel \
  --namespace=gloo-mesh \
  --kube-context $MGMT \
  --create-namespace

helm upgrade --install gloo-platform gloo-platform/gloo-platform \
  --version=$GLOO_PLATFORM_VERSION \
  --devel \
  --namespace=gloo-mesh \
  --kube-context $MGMT \
  --create-namespace \
  --set licensing.glooMeshLicenseKey=$GLOO_PLATFORM_LICENSE_KEY \
  --set licensing.glooTrialLicenseKey=$GLOO_PLATFORM_LICENSE_KEY \
  --set licensing.glooGatewayLicenseKey=$GLOO_PLATFORM_LICENSE_KEY \
  -f gloo-mgmt-values.yaml

MGMT_SERVER_NETWORKING_DOMAIN=$(kubectl get svc -n gloo-mesh gloo-mesh-mgmt-server --context $MGMT -o jsonpath='{.status.loadBalancer.ingress[0].*}')
MGMT_SERVER_NETWORKING_PORT=$(kubectl -n gloo-mesh get service gloo-mesh-mgmt-server --context $MGMT -o jsonpath='{.spec.ports[?(@.name=="grpc")].port}')
GLOO_TELEMETRY_GATEWAY=$(kubectl get svc -n gloo-mesh gloo-telemetry-gateway --context $MGMT -o jsonpath='{.status.loadBalancer.ingress[0].*}'):$(kubectl --context ${MGMT} -n gloo-mesh get svc gloo-telemetry-gateway -o jsonpath='{.spec.ports[?(@.port==4317)].port}')
MGMT_SERVER_NETWORKING_ADDRESS=${MGMT_SERVER_NETWORKING_DOMAIN}:${MGMT_SERVER_NETWORKING_PORT}

echo "Mgmt Plane Address: $MGMT_SERVER_NETWORKING_ADDRESS"
echo "Metrics Gateway Address: $GLOO_TELEMETRY_GATEWAY"

mkdir tmp
# Public CA cert used for TLS validation with the management plane
kubectl get secret relay-root-tls-secret -n gloo-mesh --context $MGMT -o jsonpath='{.data.ca\.crt}' | base64 -d > tmp/ca.crt
# Token to authenticate agents with the management plane
kubectl get secret relay-identity-token-secret -n gloo-mesh --context $MGMT -o jsonpath='{.data.token}' | base64 -d > tmp/token

kubectl apply --context $MGMT -f- <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: KubernetesCluster
metadata:
  name: $CLUSTER1
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
---
apiVersion: admin.gloo.solo.io/v2
kind: KubernetesCluster
metadata:
  name: $CLUSTER2
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
EOF

# Gloo Mesh agent cluster 1

kubectl create namespace gloo-mesh --context $CLUSTER1

# Add token and ca cert
kubectl create secret generic relay-root-tls-secret -n gloo-mesh --context $CLUSTER1 --from-file ca.crt=tmp/ca.crt
kubectl create secret generic relay-identity-token-secret -n gloo-mesh --context $CLUSTER1 --from-file token=tmp/token

helm upgrade --install gloo-platform-crds gloo-platform/gloo-platform-crds \
  --version=$GLOO_PLATFORM_VERSION \
  --devel \
  --namespace=gloo-mesh \
  --kube-context $CLUSTER1 \
  --create-namespace

helm upgrade --install gloo-agent gloo-platform/gloo-platform \
  --version=$GLOO_PLATFORM_VERSION \
  --namespace gloo-mesh \
  --kube-context $CLUSTER1 \
  --set glooAgent.relay.serverAddress=$MGMT_SERVER_NETWORKING_ADDRESS \
  --set common.cluster=$CLUSTER1 \
  --set telemetryCollector.config.exporters.otlp.endpoint=$GLOO_TELEMETRY_GATEWAY \
  -f 01-install-gloo-platform/gloo-agent-values.yaml


# Gloo Mesh Agent cluster2 

kubectl create namespace gloo-mesh --context $CLUSTER2

# Add token and ca cert
kubectl create secret generic relay-root-tls-secret -n gloo-mesh --context $CLUSTER2 --from-file ca.crt=tmp/ca.crt
kubectl create secret generic relay-identity-token-secret -n gloo-mesh --context $CLUSTER2 --from-file token=tmp/token

helm upgrade --install gloo-platform-crds gloo-platform/gloo-platform-crds \
  --version=$GLOO_PLATFORM_VERSION \
  --devel \
  --namespace=gloo-mesh \
  --kube-context $CLUSTER2 \
  --create-namespace
  
helm upgrade --install gloo-agent gloo-platform/gloo-platform \
  --version=$GLOO_PLATFORM_VERSION \
  --namespace gloo-mesh \
  --kube-context $CLUSTER2 \
  --set glooAgent.relay.serverAddress=$MGMT_SERVER_NETWORKING_ADDRESS \
  --set common.cluster=$CLUSTER2 \
  --set telemetryCollector.config.exporters.otlp.endpoint=$GLOO_TELEMETRY_GATEWAY \
  -f 01-install-gloo-platform/gloo-agent-values.yaml

# Install Istio
kubectl apply -f istio.yaml --context $MGMT

# Root Trust Policy
kubectl apply -n gloo-mesh --context $MGMT -f -<<EOF
apiVersion: admin.gloo.solo.io/v2
kind: RootTrustPolicy
metadata:
  name: root-trust-policy
  namespace: gloo-mesh
spec:
  config:
    mgmtServerCa:
      generated: {}
    autoRestartPods: true
EOF

# Setup Kafka
kubectl create namespace ops-team --context $MGMT
kubectl create namespace producers --context $CLUSTER1
kubectl label namespace producers istio.io/rev=1-16 --context $CLUSTER1

helm repo add confluentinc https://packages.confluent.io/helm
helm repo update

kubectl create namespace confluent --context $CLUSTER2
kubectl label namespace confluent istio.io/rev=1-16 --context $CLUSTER2

helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes -n confluent --kube-context $CLUSTER2

kubectl apply -f kafka-deploy.yaml --context $CLUSTER2

kubectl apply -f producer.yaml --context $CLUSTER1
