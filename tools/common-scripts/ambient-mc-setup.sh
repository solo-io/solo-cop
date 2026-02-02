#!/bin/bash

# Check if license key is present
if [ -z "$GLOO_MESH_LICENSE_KEY" ]
then
  echo "[ERROR] Please set GLOO_MESH_LICENSE_KEY env var before running the script"
  echo; echo "export GLOO_MESH_LICENSE_KEY=<license_key_string>"
  exit 1
fi

# Check if REPO_KEY is present
if [ -z "$REPO_KEY" ]
then
  echo "[ERROR] Please set REPO_KEY env var before running the script. 12-character hash at the end of the minor version repo URL. docs https://support.solo.io/hc/en-us/articles/4414409064596-Istio-images-built-by-Solo-io"
  echo; echo "export REPO_KEY=<REPO_KEY_STRING>"
  exit 1
fi

# Check if cloud-provider-kind process is running
echo "[DEBUG] Check if cloud-provider-kind process is currently running"
ps -eaf | grep cloud-provider-kind | grep -v color | grep -v "grep"
# Check the exit status of the previous command
if [ $? -ne 0 ]; then
  echo "[ERROR] cloud-provider-kind process is currently not running. Please run cloud-provider-kind in a terminal window"
  exit 1
fi

# Delete existing clusters if present
for i in {1..2}; do
  CLUSTER="ambient-cluster${i}"
  kind delete cluster --name ${CLUSTER}
  kubectl config delete-context ${CLUSTER}
  sleep 2
done;
sleep 2

# env vars
# 12-character hash at the end of the minor version repo URL
# docs: https://support.solo.io/hc/en-us/articles/4414409064596-Istio-images-built-by-Solo-io
HELM_REPO=us-docker.pkg.dev/gloo-mesh/istio-helm-${REPO_KEY}
ISTIO_REPO=us-docker.pkg.dev/gloo-mesh/istio-${REPO_KEY}
ISTIO_VERSION=1.28.2
SUFFIX_SOLO=solo
ISTIO_TAG="${ISTIO_VERSION}-${SUFFIX_SOLO}"
HELM_CHART_VERSION="${ISTIO_VERSION}-${SUFFIX_SOLO}"


for i in {1..2}; do

cat <<EOF | kind create cluster --name="ambient-cluster${i}" --config=-
# three node (two workers) cluster config
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    apiVersion: kubeadm.k8s.io/v1beta3
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "topology.kubernetes.io/region=us-east-${i},topology.kubernetes.io/zone=us-east-${i}a"
- role: worker
  kubeadmConfigPatches:
  - |
    kind: JoinConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "topology.kubernetes.io/region=us-east-${i},topology.kubernetes.io/zone=us-east-${i}b"
- role: worker
  kubeadmConfigPatches:
  - |
    kind: JoinConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "topology.kubernetes.io/region=us-east-${i},topology.kubernetes.io/zone=us-east-${i}c"
EOF

  kubectl --context kind-ambient-cluster${i} -n kube-system rollout status deploy/coredns
  kubectl --context kind-ambient-cluster${i} -n local-path-storage rollout status deploy/local-path-provisioner
  kubectl --context kind-ambient-cluster${i} -n kube-system rollout status ds/kindnet
  kubectl --context kind-ambient-cluster${i} -n kube-system rollout status ds/kube-proxy

  # Rename context to ambient-cluster${i}
  kubectl config rename-context kind-ambient-cluster${i} ambient-cluster${i}

done

curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -
cd istio-${ISTIO_VERSION}

mkdir -p certs
pushd certs
make -f ../tools/certs/Makefile.selfsigned.mk root-ca

function create_cacerts_secret() {
  context=${1:?context}
  cluster=${2:?cluster}
  make -f ../tools/certs/Makefile.selfsigned.mk ${cluster}-cacerts
  kubectl --context=${context} create ns istio-system || true
  kubectl --context=${context} create secret generic cacerts -n istio-system \
    --from-file=${cluster}/ca-cert.pem \
    --from-file=${cluster}/ca-key.pem \
    --from-file=${cluster}/root-cert.pem \
    --from-file=${cluster}/cert-chain.pem
}

create_cacerts_secret ambient-cluster1 ambient-cluster1
create_cacerts_secret ambient-cluster2 ambient-cluster2

cd ../..

for CLUSTER in ambient-cluster1 ambient-cluster2; do

kubectl --context ${CLUSTER} apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml

helm upgrade -i istio-base oci://${HELM_REPO}/base                     \
     --namespace istio-system                                          \
     --create-namespace                                                \
     --version "${HELM_CHART_VERSION}"                                 \
     --wait --kube-context $CLUSTER

helm upgrade -i istiod oci://${HELM_REPO}/istiod \
--namespace istio-system                              \
--version "${HELM_CHART_VERSION}"                     \
--wait --kube-context $CLUSTER                       \
--values - <<EOF
profile: ambient
hub: ${ISTIO_REPO}
tag: ${ISTIO_TAG}
env:
  PEERING_ENABLE_FLAT_NETWORKS: "false"
  PILOT_SKIP_VALIDATE_TRUST_DOMAIN: "true"
global:
  hub: ${ISTIO_REPO}
  tag: ${ISTIO_TAG}
  meshID: mesh1
  multiCluster:
    clusterName: ${CLUSTER}
    enabled: true
  network: ${CLUSTER}
meshConfig:
  defaultConfig:
    proxyMetadata:
      ISTIO_META_DNS_CAPTURE: "true"
  trustDomain: "${CLUSTER}"
platforms:
  peering:
    enabled: true
license:
  value: ${GLOO_MESH_LICENSE_KEY}
EOF

helm upgrade -i istio-cni oci://${HELM_REPO}/cni \
--namespace istio-system                         \
--version "${HELM_CHART_VERSION}"                \
--wait --kube-context $CLUSTER                  \
--values - << EOF
hub: ${ISTIO_REPO}
tag: ${ISTIO_TAG}
profile: ambient
excludeNamespaces:
  - istio-system
  - kube-system
EOF

helm upgrade -i ztunnel oci://${HELM_REPO}/ztunnel \
--namespace istio-system                           \
--version "${HELM_CHART_VERSION}"                  \
--wait --kube-context $CLUSTER                    \
--values - << EOF
profile: ambient
hub: ${ISTIO_REPO}
tag: ${ISTIO_TAG}
env:
  SKIP_VALIDATE_TRUST_DOMAIN: "true"
  L7_ENABLED: "true"
multiCluster:
  clusterName: ${CLUSTER}
network: ${CLUSTER}
EOF

kubectl label namespace istio-system topology.istio.io/network=${CLUSTER} --overwrite --context ${CLUSTER} || true

done

for i in {1..2}; do
CLUSTER="ambient-cluster${i}"
kubectl create namespace istio-eastwest --context ${CLUSTER}

kubectl --context ${CLUSTER} apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  annotations:
    peering.solo.io/data-plane-service-type: loadbalancer
  labels:
    istio.io/expose-istiod: "15012"
    topology.istio.io/cluster: ${CLUSTER}
    topology.istio.io/network: ${CLUSTER}
    topology.kubernetes.io/region: "us-east-${i}"
  name: istio-eastwest
  namespace: istio-eastwest
spec:
  gatewayClassName: istio-eastwest
  listeners:
  - name: cross-network
    port: 15008
    protocol: HBONE
    tls:
      mode: Passthrough
  - name: xds-tls
    port: 15012
    protocol: TLS
    tls:
      mode: Passthrough
EOF

sleep 1
  kubectl rollout status deployment/istio-eastwest -n istio-eastwest --context ${CLUSTER}
done

# Deploy eastwest gateways for peering
for CURRENT_CLUSTER_INDEX in {1..2}; do
  CURRENT_CLUSTER="ambient-cluster${CURRENT_CLUSTER_INDEX}"
  
  OTHER_CLUSTER_INDEX=2
  if [ $CURRENT_CLUSTER_INDEX -eq 2 ]; then
    OTHER_CLUSTER_INDEX=1
  fi
  OTHER_CLUSTER="ambient-cluster${OTHER_CLUSTER_INDEX}"
  ISTIO_EW_GATEWAY_ADDR_OTHER_CLUSTER=$(kubectl --context ${OTHER_CLUSTER} get svc istio-eastwest -n istio-eastwest --no-headers | awk '{print $4}')

  kubectl --context ${CURRENT_CLUSTER} apply -f - <<EOF
---
# generated from context: cluster2
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  annotations:
    gateway.istio.io/service-account: istio-eastwest
    gateway.istio.io/trust-domain: "${OTHER_CLUSTER}"
    peering.solo.io/preferred-data-plane-service-type: loadbalancer
  labels:
    topology.istio.io/cluster: "${OTHER_CLUSTER}"
    topology.istio.io/network: "${OTHER_CLUSTER}"
    topology.kubernetes.io/region: "us-east-${OTHER_CLUSTER_INDEX}"
  name: "istio-remote-peer-${OTHER_CLUSTER}"
  namespace: istio-eastwest
spec:
  addresses:
  - type: IPAddress
    value: "${ISTIO_EW_GATEWAY_ADDR_OTHER_CLUSTER}"
  gatewayClassName: istio-remote
  listeners:
  - name: xds-tls
    port: 15012
    protocol: TLS
    tls:
      mode: Passthrough
EOF
done;


for i in {1..2}; do
  echo; echo "Deploying client and server apps in ambient-cluster${i}..."
  CLUSTER="ambient-cluster${i}"

  for ns in "client-app" "httpbin"; do
    kubectl --context ${CLUSTER} create namespace ${ns}
    kubectl --context ${CLUSTER} label namespace "${ns}" istio.io/dataplane-mode=ambient
  done

kubectl --context ${CLUSTER} --namespace "client-app" apply -f - << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: "netshoot"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "netshoot"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: "netshoot"
  template:
    metadata:
      labels:
        app: "netshoot"
    spec:
      serviceAccountName: "netshoot"
      containers:
      - name: "netshoot"
        image: nicolaka/netshoot
        command: ["/bin/sh", "-c", "wget https://github.com/tsenart/vegeta/releases/download/v12.12.0/vegeta_12.12.0_linux_arm64.tar.gz -O vegeta.tar.gz ; tar -xzf vegeta.tar.gz ; mv vegeta /usr/local/bin/ ;echo \"GET http://httpbin.httpbin.mesh.internal:8000/headers\" >> /tmp/targets.txt ; while true; do sleep 10; echo 'Sleeping forever...'; done"]
EOF
kubectl --context ${CLUSTER} --namespace "client-app" rollout status deployment/netshoot

kubectl --context ${CLUSTER} --namespace "httpbin" apply -f - << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: httpbin
  namespace: httpbin
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: httpbin
  labels:
    app: httpbin
    service: httpbin
spec:
  ports:
    - name: http
      port: 8000
      targetPort: 8080
    - name: tcp
      port: 9000
  selector:
    app: httpbin
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  namespace: httpbin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v1
  template:
    metadata:
      labels:
        app: httpbin
        version: v1
    spec:
      serviceAccountName: httpbin
      containers:
        - image: docker.io/mccutchen/go-httpbin:v2.6.0
          imagePullPolicy: IfNotPresent
          name: httpbin
          command: [ go-httpbin ]
          args:
            - "-port"
            - "8080"
            - "-max-duration"
            - "600s" # override default 10s
          ports:
            - containerPort: 8080
        - name: curl
          image: curlimages/curl:7.83.1
          resources:
            requests:
              cpu: "100m"
            limits:
              cpu: "200m"
          imagePullPolicy: IfNotPresent
          command:
            - "tail"
            - "-f"
            - "/dev/null"
EOF
kubectl --context ${CLUSTER} --namespace "httpbin" rollout status deployment/httpbin
done;

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community

for i in {1..2}; do
  echo; echo "Deploying monitoring stack in ambient-cluster${i}..."
  CLUSTER="ambient-cluster${i}"
  kubectl --context ${CLUSTER} create namespace monitoring
helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --version 80.4.2 \
  --namespace monitoring \
  --create-namespace \
  --kube-context ${CLUSTER} \
  --wait \
  --values - <<EOF
alertmanager:
  enabled: false
grafana:
  adminPassword: "prom-operator"
  service:
    type: LoadBalancer
    port: 3000
nodeExporter:
  enabled: false
prometheus:
  service:
    type: LoadBalancer
  prometheusSpec:
    ruleSelectorNilUsesHelmValues: false
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false
EOF
done;

for i in {1..2}; do
  CLUSTER="ambient-cluster${i}"
  kubectl --context ${CLUSTER} apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ctrl-plane-monitoring-istio-pilot
  namespace: istio-system
spec:
  endpoints:
  - interval: 30s
    port: http-monitoring
    scheme: http
  selector:
    matchLabels:
      app: istiod
EOF

kubectl --context ${CLUSTER} apply -f- <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: ctrl-plane-monitoring-istio-cni
  namespace: istio-system
spec:
  namespaceSelector:
    matchNames:
      - istio-system
  podMetricsEndpoints:
    - port: "metrics"
      path: "/metrics"
  selector:
    matchLabels:
      app.kubernetes.io/name: istio-cni
EOF

kubectl --context ${CLUSTER} apply -f- <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: data-plane-monitoring-ztunnel
  namespace: istio-system
spec:
  namespaceSelector:
    matchNames:
      - istio-system
  podMetricsEndpoints:
    - port: "ztunnel-stats"
      path: "/stats/prometheus"
  selector:
    matchLabels:
      app: ztunnel
EOF
done;

GRAFANA_CRED="admin:prom-operator"
GRAFANA_DATASOURCE="Prometheus"
for i in {1..2}; do
  # ztunnel metrics
  DASHBOARD=21306
  REVISION=43
  echo; echo "Importing dashboards in ambient-cluster${i}..."; echo;
  CLUSTER="ambient-cluster${i}"
  GRAFANA_SVC_IP=$(kubectl --context ${CLUSTER} -n monitoring get svc kube-prometheus-stack-grafana --no-headers | awk '{print $4}')
  GRAFANA_HOST="http://${GRAFANA_SVC_IP}:3000"
curl -s "https://grafana.com/api/dashboards/${DASHBOARD}/revisions/${REVISION}/download" > /tmp/dashboard.json
    TITLE=$(cat /tmp/dashboard.json | jq -r '.title')
    echo "Importing $TITLE (revision ${REVISION}, id ${DASHBOARD})..."
    curl -s -k -u "$GRAFANA_CRED" -XPOST \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d "{\"dashboard\":$(cat /tmp/dashboard.json),\"overwrite\":true, \
            \"inputs\":[{\"name\":\"DS_PROMETHEUS\",\"type\":\"datasource\", \
            \"pluginId\":\"prometheus\",\"value\":\"$GRAFANA_DATASOURCE\"}]}" \
        $GRAFANA_HOST/api/dashboards/import
# Import all Istio dashboards
for DASHBOARD in 7639 11829 7636 7630 7645 13277; do
    REVISION="$(curl -s https://grafana.com/api/dashboards/${DASHBOARD}/revisions -s | jq ".items[] | select(.description | contains(\"${VERSION}\")) | .revision" | tail -n 1)"
    curl -s "https://grafana.com/api/dashboards/${DASHBOARD}/revisions/${REVISION}/download" > /tmp/dashboard.json
    TITLE=$(cat /tmp/dashboard.json | jq -r '.title')
    echo "Importing $TITLE (revision ${REVISION}, id ${DASHBOARD})..."
    curl -s -k -u "$GRAFANA_CRED" -XPOST \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d "{\"dashboard\":$(cat /tmp/dashboard.json),\"overwrite\":true, \
            \"inputs\":[{\"name\":\"DS_PROMETHEUS\",\"type\":\"datasource\", \
            \"pluginId\":\"prometheus\",\"value\":\"$GRAFANA_DATASOURCE\"}]}" \
        $GRAFANA_HOST/api/dashboards/import
done
done;

echo; echo "________________________________________________________________________________"; echo;
for i in {1..2}; do
  CLUSTER="ambient-cluster${i}"
  GRAFANA_SVC_IP=$(kubectl --context ${CLUSTER} -n monitoring get svc kube-prometheus-stack-grafana --no-headers | awk '{print $4}')
  GRAFANA_HOST="http://${GRAFANA_SVC_IP}:3000"
  echo; echo "${CLUSTER} Grafana URL: ${GRAFANA_HOST}/dashboards?query=istio - username: admin, password: prom-operator"
done;

# make global for failover with httpbin.httpbin.mesh.internal
for i in {1..2}; do
  CLUSTER="ambient-cluster${i}"
  kubectl --context ${CLUSTER} label namespace httpbin solo.io/service-scope=global
done;

echo; echo "________________________________________________________________________________"; echo;
echo "Run the following to test client-server comms with auto failover"; echo;
echo 'kubectl --context ambient-cluster1 --namespace client-app exec -it deploy/netshoot -- sh -c "echo \"GET http://httpbin.httpbin.mesh.internal:8000/headers\" | vegeta attack  -rate=100 -duration=5s < /tmp/targets.txt | vegeta report"'
echo;
echo "________________________________________________________________________________"; echo;

# # # Useful commands and queries
# # istioctl zc certificate ztunnel-kc2zs.istio-system
# # istio_requests_total {reporter="source",response_code="200",destination_service="httpbin.httpbin.mesh.internal"}

# Alternate
echo; echo "_____________________________ Failover with httpbin.httpbin.svc.cluster.local __________________________________________________"; echo;
# https://docs.solo.io/gloo-mesh/latest/ambient/multicluster/multi-apps/overview/#endpoint-traffic-control
for i in {1..2}; do
  CLUSTER="ambient-cluster${i}"
  kubectl --context ${CLUSTER} label namespace httpbin solo.io/service-scope=global
  kubectl --context ${CLUSTER} label namespace httpbin solo.io/service-takeover=true
  kubectl --context ${CLUSTER} annotate service httpbin -n httpbin networking.istio.io/traffic-distribution=PreferClose --overwrite
done;
echo "Run the following to test client-server comms with auto failover"; echo;
kubectl --context ambient-cluster1 --namespace client-app exec -it deploy/netshoot -- sh -c "echo \"GET http://httpbin.httpbin.svc.cluster.local:8000/headers\" | vegeta attack -rate=1000 -duration=5s | vegeta report"
## o/p
## Requests      [total, rate, throughput]         4999, 1000.19, 1000.15
## Duration      [total, attack, wait]             4.998s, 4.998s, 202.708µs
## Latencies     [min, mean, 50, 90, 95, 99, max]  136.834µs, 247.067µs, 238.036µs, 308.768µs, 335.375µs, 440.573µs, 2.426ms
## Bytes In      [total, mean]                     1153659, 230.78
## Bytes Out     [total, mean]                     0, 0.00
## Success       [ratio]                           100.00%
## Status Codes  [code:count]                      200:4999
## Error Set:
## scale dowm in cluster1 
kubectl --context ambient-cluster1 --namespace httpbin scale deployment/httpbin --replicas=0
## re-run
kubectl --context ambient-cluster1 --namespace client-app exec -it deploy/netshoot -- sh -c "echo \"GET http://httpbin.httpbin.svc.cluster.local:8000/headers\" | vegeta attack -rate=1000 -duration=5s | vegeta report"
## o/p
## Requests      [total, rate, throughput]         4999, 1000.22, 1000.14
## Duration      [total, attack, wait]             4.998s, 4.998s, 425.917µs
## Latencies     [min, mean, 50, 90, 95, 99, max]  246.167µs, 522.109µs, 401.626µs, 491.477µs, 534.427µs, 1.005ms, 31.563ms
## Bytes In      [total, mean]                     1153659, 230.78
## Bytes Out     [total, mean]                     0, 0.00
## Success       [ratio]                           100.00%
## Status Codes  [code:count]                      200:4999
## Error Set:
echo;
echo; echo "_____________________________ Failover with httpbin.httpbin.svc.cluster.local __________________________________________________"; echo;

echo; echo "______________________________Check Grafana URL__________________________________________________"; echo;
CLUSTER="ambient-cluster1"
GRAFANA_SVC_IP=$(kubectl --context ${CLUSTER} -n monitoring get svc kube-prometheus-stack-grafana --no-headers | awk '{print $4}')
GRAFANA_HOST="http://${GRAFANA_SVC_IP}:3000"
echo; echo "${CLUSTER} Grafana URL: ${GRAFANA_HOST}/explore - username: admin, password: prom-operator"
echo 'istio_requests_total {reporter="source",response_code="200",destination_service="httpbin.httpbin.svc.cluster.local"}'
echo; echo "______________________________Check Grafana URL__________________________________________________"; echo;
## query to run and check traffic going to cluster2
## istio_requests_total {reporter="source",response_code="200",destination_service="httpbin.httpbin.svc.cluster.local"}