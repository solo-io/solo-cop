## Deploy RootTrustPolicy

```sh
cat << EOF | kubectl --context $MGMT_CONTEXT apply -f -
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
```

## Gloo Mesh Configuration

```sh
# Create workspaces and namespaces for configuration
kubectl apply --context $MGMT_CONTEXT -f gloo-mesh-config/workspaces.yaml

```

## install apps
```sh
kubectl apply -n web-ui -f cluster1/web-ui.yaml --context $REMOTE_CONTEXT1
kubectl apply -n backend-apis -f cluster1/backend-apis-cluster1.yaml --context $REMOTE_CONTEXT1
```

## expose frontend

In order to expose the frontend application in the web-ui namespace, the Ops team first needs to setup the Istio ingress gateway to allow incomming traffic. This is done with a `VirtualGateway`. The Ops team determines which hosts and ports other teams can use by configuring the `allowedRouteTables`. In this case we will allow the Web team to define routes for their application. 

```sh
# view the VirtualGateway configuration
cat gloo-mesh-config/virtual-gateway.yaml

# apply the VirtualGateway to the mgmt cluster in the ops-team namespace
kubectl apply --context $MGMT_CONTEXT -f gloo-mesh-config/virtual-gateway.yaml
```

The Web team has been granted the ability to attach route tables to the `VirtualGateway`. Using a `RouteTable` the Web team can forward traffic from the VirtualGateway to their `frontend` application. 

```sh
# view the route table configuration
cat gloo-mesh-config/route-table.yaml

# apply the RouteTable to the mgmt cluster in the web-team namespace
kubectl apply --context $MGMT_CONTEXT -f gloo-mesh-config/route-table.yaml
```

* Now we can view the `Online Boutique` application via the `VirtualGateway`


## Checkout Serivce Feature

![](./images/checkout-feature.png)

Currently the `Checkout` feature is missing from our Online Boutique. The Backend APIs team has finished the feature and plans to deploy it to `cluster2`. This would normally cause issues because the `frontend` application which depends on this feature is deployed to `cluster1`. Gloo Mesh has the ability to create globally addressable multi-cluster services using a `VirtualDestination` configuration. The `VirtualDestination` allows the user to create a unique hostname that allows the selected service(s) to be reachable from anywhere Gloo Mesh is deployed. Since users can select their services using labels, VirtualDestinations are dynamic, adding and removing services as they come and go. We can demonstrate this with the `Checkout` feature.

```yaml
apiVersion: networking.gloo.solo.io/v2
kind: VirtualDestination
metadata:
  name: checkout
  namespace: backend-apis-team
spec:
  # Global hostname available everywhere
  hosts:
  - checkout.mesh.internal
  # services that available at the above address
  services:
  - labels:
      app: checkoutservice
  ports:
  - number: 80
    protocol: GRPC
    targetPort:
      name: grpc
```

First we are going to deploy the checkout feature to `cluster2`. It wont immediately be available to the frontend yet until we create the `VirtualDestination`. 

```sh
kubectl apply -n backend-apis -f cluster2/checkout-feature.yaml --context $REMOTE_CONTEXT2
```

In this demo the Backend APIs team needs to create 5 VirtualDestinations because the checkout feature makes requests to the `cart/currency/product-catalog` services in `cluster1` and the frontend also needs to communicate with the `shipping` service deployed with the `Catalog` feature. We did add a small load tester for the `Checkout` feature in `cluster2` so that you can view it in the `Gloo Mesh UI`.

```sh
# Create the 5 VirtualDestinations in the backend-apis-team namespace in the management plane
kubectl apply -n backend-apis-team -f gloo-mesh-config/virtual-destinations.yaml --context $MGMT_CONTEXT
```

* Take a look at the `Gloo Mesh Graph` and we now should see the `Checkout` feature deployed.


* Finally the Web Team will need to update thier `frontend` service to call the global hostnamed services generated by the `VirtualDestinations`. The below updates are needed for the frontend to call the `Checkout` feature.

```yaml
  - name: SHIPPING_SERVICE_ADDR
    value: "shipping.mesh.internal:80"
  - name: CHECKOUT_SERVICE_ADDR
    value: "checkout.mesh.internal:80"
  - name: PRODUCT_CATALOG_SERVICE_ADDR
    value: "product-catalog.mesh.internal:80"
  - name: CURRENCY_SERVICE_ADDR
    value: "currency.mesh.internal:80"
```

```sh
# Update the frontend application to use global hostnames
kubectl apply -n web-ui -f cluster1/web-ui-with-checkout.yaml --context $REMOTE_CONTEXT1
```