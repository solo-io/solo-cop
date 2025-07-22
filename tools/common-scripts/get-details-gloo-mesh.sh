#!/bin/bash
set -e

TIMESTAMP=$(date +%m-%d-%Y-%H%M%S)
mkdir "mesh-details-${TIMESTAMP}"
cd "mesh-details-${TIMESTAMP}"

echo
echo "[INFO] Getting the server and agent logs and saving locally..."
##
# Get the logs of the key components
# Get the Gloo Mesh Mgmt Server logs
kubectl --context ${MGMT_CONTEXT} \
    -n gloo-mesh logs \
    deployments/gloo-mesh-mgmt-server > "logs-gloo-mgmt-server-${TIMESTAMP}.txt"

# Agent logs - workload cluster 1
kubectl --context ${REMOTE_CONTEXT1} \
    -n gloo-mesh logs \
    deployments/gloo-mesh-agent > "logs-gloo-agent-cluster1-${TIMESTAMP}.txt"

# Agent logs - workload cluster 2
kubectl --context ${REMOTE_CONTEXT2} \
    -n gloo-mesh logs \
    deployments/gloo-mesh-agent > "logs-gloo-agent-cluster2-${TIMESTAMP}.txt"

echo
echo "[INFO] Getting the server and agent Deployment spec and saving locally..."
##
# Get The Deployment details of the Gloo Management cluster and the Gloo Agent -
# Agent deployment details
# Gloo Management Server deployment details
kubectl --context ${MGMT_CONTEXT} \
    -n gloo-mesh get deployments/gloo-mesh-mgmt-server \
    -o yaml > "spec-gloo-mgmt-server-${TIMESTAMP}.yaml"

# Gloo Agent deployment details
kubectl --context ${REMOTE_CONTEXT1} \
    -n gloo-mesh get deployments/gloo-mesh-agent \
    -o yaml > "spec-gloo-agent-cluster1-${TIMESTAMP}.yaml"

kubectl --context ${REMOTE_CONTEXT2} \
    -n gloo-mesh get deployments/gloo-mesh-agent \
    -o yaml > "spec-gloo-agent-cluster2-${TIMESTAMP}.yaml"

echo
echo "[INFO] Getting the list of KubernetesCluster objects in MGMT cluster and saving locally..."
##
# Get the list of KubernetesCluster CRDs registered on the Management Cluster
kubectl --context ${MGMT_CONTEXT} \
    get KubernetesCluster -A > "list-of-KubernetesCluster-CRD-${TIMESTAMP}.txt"

echo
echo "[INFO] Getting the relay address value..."
MGMT_INGRESS_ADDRESS=$(kubectl get svc -n gloo-mesh gloo-mesh-mgmt-server --context ${MGMT_CONTEXT} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
MGMT_INGRESS_PORT=$(kubectl -n gloo-mesh get service gloo-mesh-mgmt-server --context ${MGMT_CONTEXT} -o jsonpath='{.spec.ports[?(@.name=="grpc")].port}')
RELAY_ADDRESS=${MGMT_INGRESS_ADDRESS}:${MGMT_INGRESS_PORT}
echo "${RELAY_ADDRESS}" > "relay-address-value-${TIMESTAMP}.txt"

cd ..
tar -cf "mesh-details-${TIMESTAMP}.tar.gz" "mesh-details-${TIMESTAMP}"
rm -rf "mesh-details-${TIMESTAMP}"

echo
echo "[INFO] Logs saved in mesh-details-${TIMESTAMP}.tar.gz Please use the following command to extract the files-"
echo
echo "tar -xvf mesh-details-${TIMESTAMP}.tar.gz"
echo
