# Weighted Routing using locality

This example shows you how you can manually forward traffic to different localities using the FailoverPolicy

```yaml
apiVersion: resilience.policy.gloo.solo.io/v2
kind: FailoverPolicy
metadata:
  name: failover
  namespace: web-team
spec:
  applyToDestinations:
  - kind: VIRTUAL_DESTINATION
    selector:
      namespace: web-team
  config:
    localityMappings:
    - from:
        region: us-east-1
      to:
      - region: us-west-2
        weight: 75
      - region: us-east-1
        weight: 25
```

## Install Gloo Mesh

```sh
export GLOO_MESH_VERSION=v2.1.0

export MGMT=mgmt
export CLUSTER1=cluster1
export CLUSTER2=cluster2


curl -sL https://run.solo.io/meshctl/install | GLOO_MESH_VERSION=${GLOO_MESH_VERSION} sh -

export PATH=$HOME/.gloo-mesh/bin:$PATH

meshctl version

meshctl install \
  --kubecontext $MGMT \
  --set mgmtClusterName=$MGMT \
  --license $GLOO_MESH_LICENSE_KEY

meshctl cluster register \
  --kubecontext=$MGMT \
  --remote-context=$CLUSTER1 \
  $CLUSTER1

meshctl cluster register \
  --kubecontext=$MGMT \
  --remote-context=$CLUSTER2 \
  $CLUSTER2

cat << EOF | kubectl --context ${MGMT} apply -f -
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

kubectl create namespace ops-team --context $MGMT
kubectl create namespace web-team --context $MGMT
kubectl create namespace backend-apis-team --context $MGMT
kubectl apply -f workspaces.yaml --context $MGMT

kubectl apply -f istio-install.yaml --context $MGMT

kubectl create namespace web-ui --context $CLUSTER1
kubectl label ns web-ui istio-injection=enabled --context $CLUSTER1

kubectl create namespace web-ui --context $CLUSTER2
kubectl label ns web-ui istio-injection=enabled --context $CLUSTER2

kubectl apply -n web-ui --context $CLUSTER1 -f cluster1-apps.yaml
kubectl apply -n web-ui --context $CLUSTER2 -f cluster2-apps.yaml
```

## Configuration


1. VirtualDestination
```yaml
kubectl --context ${MGMT} apply -f - <<EOF
apiVersion: networking.gloo.solo.io/v2
kind: VirtualDestination
metadata:
  name: frontend
  namespace: web-team
spec:
  hosts:
  - frontend.web-ui-team.solo-io.mesh
  services:
  - labels:
      app: frontend
  ports:
  - number: 80
    protocol: HTTP
    targetPort:
      name: http
EOF
```

2. Routing

```yaml
kubectl --context ${MGMT} apply -f - <<EOF
apiVersion: networking.gloo.solo.io/v2
kind: VirtualGateway
metadata:
  name: north-south-gw
  namespace: ops-team
spec:
  workloads:
    - selector:
        labels:
          istio: ingressgateway
        cluster: cluster1
        namespace: istio-ingress
  listeners: 
    - http: {}
      port:
        number: 80
      allowedRouteTables:
        - host: '*'
          selector:
            workspace: web-team
---
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: frontend
  namespace: web-team
  labels:
    lab: failover
spec:
  hosts:
    - '*'
  virtualGateways:
    - name: north-south-gw
      namespace: ops-team
      cluster: mgmt
  workloadSelectors: []
  http:
    - name: frontend
      labels:
        virtual-destination: frontend
      forwardTo:
        destinations:
          - ref:
              name: frontend
              namespace: web-team
            kind: VIRTUAL_DESTINATION
            port:
              number: 80
EOF
```

* Test Routing
```
for i in {1..6}; do curl -sSk http://localhost:8080 | grep "Cluster="; done
Cluster=cluster-2
Cluster=cluster-1
Cluster=cluster-1
Cluster=cluster-2
Cluster=cluster-1
Cluster=cluster-2
```


3. FailoverPolicy / Outlier Detection

```yaml
kubectl --context ${MGMT} apply -f - <<EOF
apiVersion: resilience.policy.gloo.solo.io/v2
kind: FailoverPolicy
metadata:
  name: failover
  namespace: web-team
spec:
  applyToDestinations:
  - kind: VIRTUAL_DESTINATION
    selector:
      namespace: web-team
  config:
    localityMappings:
    - from:
        region: us-east-1
      to:
      - region: us-west-2
        weight: 100
      # Omitted because Istio doesnt honor 0 weight, just dont specify it
      #- region: us-east-1
      #  weight: 0
---
apiVersion: resilience.policy.gloo.solo.io/v2
kind: OutlierDetectionPolicy
metadata:
  name: outlier-detection
  namespace: web-team
spec:
  applyToDestinations:
  - kind: VIRTUAL_DESTINATION
    selector:
      namespace: web-team
  config:
    consecutiveErrors: 2
    interval: 5s
    baseEjectionTime: 15s
    maxEjectionPercent: 100
EOF
```


```sh
kubectl --context ${MGMT} apply -f - <<EOF
apiVersion: resilience.policy.gloo.solo.io/v2
kind: OutlierDetectionPolicy
metadata:
  name: outlier-detection
  namespace: web-team
spec:
  applyToDestinations:
  - kind: VIRTUAL_DESTINATION
    selector:
      namespace: web-team
  config:
    consecutiveErrors: 2
    interval: 5s
    baseEjectionTime: 15s
    maxEjectionPercent: 100
EOF

kubectl --context ${MGMT} apply -f - <<EOF
apiVersion: resilience.policy.gloo.solo.io/v2
kind: FailoverPolicy
metadata:
  name: failover
  namespace: web-team
spec:
  applyToDestinations:
  - kind: VIRTUAL_DESTINATION
    selector:
      namespace: web-team
  config:
    # enable default locality based load balancing
    localityMappings:
    - from:
        region: us-east-1
      to:
      - region: us-west-2
        weight: 100
      # Omitted because Istio doesnt honor 0 weight, just dont specify it
      #- region: us-east-1
      #  weight: 0
EOF
```


## Test Routing
```sh
for i in {1..6}; do curl -sSk http://localhost:8080 | grep "Cluster="; done
```

```
for i in {1..6}; do curl -sSk http://localhost:8080 | grep "Cluster="; done
Cluster=cluster-2
Cluster=cluster-2
Cluster=cluster-2
Cluster=cluster-2
Cluster=cluster-2
Cluster=cluster-2
```