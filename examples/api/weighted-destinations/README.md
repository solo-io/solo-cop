# <center>Weighted Destination Routing</center>

## GRPC Weighted Destination Routing (Single Cluster)

To illustrate how Gloo Mesh can provide weighted destination routing within a single cluster, we will use the Online Boutique application.  This application is a microservices-based shopping cart application backed by grpc APIs.

### Prerequisites
This example assumes the typical 3-cluster setup although it is not necessary to have 3 clusters running for the single cluster example.  We will, however, separate the management plane from the workload cluster.  At a minimum, you should have environment variables pointing to your MGMT and CLUSTER1 clusters.

We also make the assumption that you have Gloo Mesh and Istio installed.

This example uses Istio revision labels for the namespaces.  Note that if you don't want to use revision labels, just adjust the contents of the yaml files in install/online-boutique for the `Namespace` CRs.

Also, if you are installing on OpenShift, you will also need to create CNI and and add scc for anyuid to all the service accounts for both the `web-ui` and `backend-apis` namespaces.

### Install Online Boutique

We will deploy the backend microservices in the `backend-apis` namespace.

```
kubectl apply --context $CLUSTER1 -f install/online-boutique/backend-apis.yaml
```

Deploy the frontend microservice to the `web-ui` namespace.

```
kubectl apply --context $CLUSTER1 -f install/online-boutique/web-ui.yaml
```

### Configure Workspaces

First, you will need to make sure that you have a `Workspace` that handles your gateways.  This example uses one called `ops-team`.  However, if you have your own, just make sure that the `WorkspaceSettings` object imports all resources from the `web-team`.  Following is an example of our `ops-team` `Workspace`.

```
apiVersion: admin.gloo.solo.io/v2
kind: Workspace
metadata:
  name: ops-team
  namespace: gloo-mesh
spec:
  workloadClusters:
  - name: 'mgmt'
    namespaces:
    - name: ops-team
  - name: '*'
    namespaces:
    - name: istio-gateways
    - name: gloo-mesh-addons
```

Create namespaces on the management cluster to hold our new `Workspaces`.

```
kubectl create namespace web-team --context $MGMT
kubectl create namespace backend-apis-team --context $MGMT
```

Apply the following to create two new `Workspaces` for our application.

```
kubectl --context ${MGMT} apply -f - <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: Workspace
metadata:
  name: web-team
  namespace: gloo-mesh
spec:
  workloadClusters:
  - name: ${MGMT}
    namespaces:
    - name: web-team
    configEnabled: true
  - name: '*'
    namespaces:
    - name: web-ui
    configEnabled: false
---
apiVersion: admin.gloo.solo.io/v2
kind: Workspace
metadata:
  name: backend-apis-team
  namespace: gloo-mesh
spec:
  workloadClusters:
  - name: ${MGMT}
    namespaces:
    - name: backend-apis-team
    configEnabled: true
  - name: '*'
    namespaces:
    - name: backend-apis
    configEnabled: false
EOF
```

Next, we need to apply `WorkspaceSettings` so that the frontend is exposed to the gateways, but the backend-apis are only exported to the `web-team`.

You will need to make sure that the `ops-team` `WorkspaceSettings` looks similar to this so that everything is imported from the `web-team`.

```
apiVersion: admin.gloo.solo.io/v2
kind: WorkspaceSettings
metadata:
  name: ops-team
  namespace: ops-team
spec:
  importFrom:
  - workspaces:
    - name: web-team
  exportTo:
  - workspaces:
    - name: "*"
    resources:
    - kind: SERVICE
      namespace: gloo-mesh-addons
    - kind: VIRTUAL_DESTINATION
      namespace: gloo-mesh-addons
  options:
    eastWestGateways:
    - selector:
        labels:
          istio: eastwestgateway
    serviceIsolation:
      enabled: true
      trimProxyConfig: true
```

We need to set a variable (OPS_TEAM) for the `ops-team` just in case yours is different. Let's apply our `WorkspaceSettings`.

```
kubectl --context ${MGMT} apply -f - <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: WorkspaceSettings
metadata:
  name: web-team
  namespace: web-team
spec:
  importFrom:
  - workspaces:
    - name: backend-apis-team
  - workspaces:
    - name: ${OPS_TEAM}
  exportTo:
  - workspaces:
    - name: ${OPS_TEAM}
  options:
    eastWestGateways:
    - selector:
        labels:
          istio: eastwestgateway
    serviceIsolation:
      enabled: true
      trimProxyConfig: true
---
apiVersion: admin.gloo.solo.io/v2
kind: WorkspaceSettings
metadata:
  name: backend-apis-team
  namespace: backend-apis-team
spec:
  exportTo:
  - workspaces:
    - name: web-team
  importFrom:
  - workspaces:
    - name: ${OPS_TEAM}
  options:
    eastWestGateways:
    - selector:
        labels:
          istio: eastwestgateway
    # disabled to show how to use Auth Policies
    serviceIsolation:
      enabled: false
      trimProxyConfig: false
EOF
```

### Setting up Ingress Routing

If you don't already have a `VirtualGateway`, the following will get you setup with simple http routing.

```
kubectl --context ${MGMT} apply -f - <<EOF
apiVersion: networking.gloo.solo.io/v2
kind: VirtualGateway
metadata:
  name: north-south-gw
  namespace: ${OPS_TEAM}
spec:
  workloads:
    - selector:
        labels:
          istio: ingressgateway
        cluster: cluster1
        namespace: istio-gateways
  listeners: 
    - http: {}
      port:
        number: 80
      allowedRouteTables:
        - host: '*'
          selector:
            workspace: web-team
EOF
```

Now, we need a `RouteTable` definition to route traffic into our store front. If you need a non-wildcard host, then use the env variable WEB_HOST.

```
kubectl --context ${MGMT} apply -f - <<EOF
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: frontend
  namespace: web-team
spec:
  hosts:
    - '*'
  virtualGateways:
    - name: north-south-gw
      namespace: ${OPS_TEAM_NS}
      cluster: ${MGMT}
  workloadSelectors: []
  http:
    - name: frontend
      forwardTo:
        destinations:
          - ref:
              name: frontend
              namespace: web-ui
              cluster: ${CLUSTER1}
            port:
              number: 80
EOF
```

### Deploy Checkout Feature

Deploy the checkout feature to cluster2

```
kubectl apply --context $CLUSTER2 -f install/online-boutique/checkout-feature.yaml
```

Let's also add the checkout feature to cluster1.

```
kubectl apply --context $CLUSTER1 -f install/online-boutique/checkout-feature.yaml
```

Create a VirtualDestination that takes over the local service name.

```
kubectl --context ${MGMT} apply -f - <<EOF
apiVersion: networking.gloo.solo.io/v2
kind: VirtualDestination
metadata:
  name: checkout
  namespace: backend-apis-team
spec:
  hosts:
  - checkoutservice.backend-apis-team.solo-io.mesh
  services:
  - labels:
      app: checkoutservice
  ports:
  - number: 80
    protocol: GRPC
    targetPort:
      name: grpc
EOF
```

Now, let's create a RouteTable that splits traffic evenly across both clusters.

```
kubectl --context ${MGMT} apply -f - <<EOF
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: checkoutservice
  namespace: backend-apis-team
spec:
  hosts:
    - 'checkoutservice.backend-apis.svc.cluster.local'
  workloadSelectors:
  - selector:
      workspace: web-team
      cluster: ${CLUSTER1}
      labels:
        app: frontend
  http:
    - name: checkoutservice
      matchers:
      - uri:
          prefix: /
      forwardTo:
        destinations:
          - kind: VIRTUAL_DESTINATION
            ref:
              name: checkout
              namespace: backend-apis-team
              cluster: ${MGMT}
            subset:
              version: v1
            weight: 50
          - kind: VIRTUAL_DESTINATION
            ref:
              name: checkout
              namespace: backend-apis-team
              cluster: ${MGMT}
            subset:
              version: v2
            weight: 50
EOF
```