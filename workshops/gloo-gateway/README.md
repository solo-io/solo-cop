![Gloo Mesh Enterprise](images/gloo-mesh-2.0-banner.png)

# <center>Gloo Gateway Workshop</center>

## Table of Contents

* [Introduction](#introduction)
* [Lab 1 - Deploy Kubernetes clusters](#Lab-1)
* [Lab 2 - Deploy Gloo Mesh](#Lab-2)
* [Lab 3 - Deploy Gateway](#Lab-3)
* [Lab 4 - Deploy Online Boutique Sample Application](#Lab-4)
* [Lab 5 - Configure Gloo Mesh](#Lab-5)
* [Lab 6 - Routing](#Lab-6)
* [Lab 7 - Policies](#Lab-7)
* [Lab 8 - Security](#Lab-8)

## Introduction <a name="introduction"></a>


## Begin

To get started with this workshop, clone this repo.

```sh
git clone https://github.com/solo-io/solo-cop.git
cd solo-cop/workshops/gloo-gateway-demo && git checkout v1.0.2
```

Set these environment variables which will be used throughout the workshop.

```sh
# Used to enable Gloo Mesh (please ask for a trail license key)
export GLOO_GATEWAY_LICENSE_KEY=<licence_key>
export GLOO_PLATFORM_VERSION=v2.1.0-beta7
```

## Lab 1 - Configure/Deploy the Kubernete cluster <a name="Lab-1"></a>

```sh
kubectl config use-context <context> 
``` 

## Lab 2 - Deploy Gloo Platform <a name="Lab-2"></a>


1. Download `meshctl` command line tool and add it to your path

```sh
curl -sL https://run.solo.io/meshctl/install | GLOO_MESH_VERSION=${GLOO_PLATFORM_VERSION} sh -

export PATH=$HOME/.gloo-mesh/bin:$PATH
```

```sh
meshctl install --license $GLOO_GATEWAY_LICENSE_KEY --register --version $GLOO_PLATFORM_VERSION
```

## Lab 3 - Deploy Gloo Gateway Using Gloo Platform<a name="Lab-3"></a>


```sh
kubectl create namespace gloo-gateway
istioctl install --set hub=$ISTIO_IMAGE_REPO --set tag=$ISTIO_IMAGE_TAG  -y  -f install/istio/istiooperator-cluster1.yaml
```


```sh
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

kubectl apply -f tracks/addons-servers.yaml
```


## Lab 4 - Deploy Online Boutique Sample Application<a name="Lab-4"></a>

![online-boutique](images/online-boutique.png)

1. Deploy the Online Boutique backend microservices to `cluster1` in the `backend-apis` namespace.

```sh
kubectl apply -f install/online-boutique/backend-apis.yaml
```

2. Deploy the frontend microservice to the `web-ui` namespace in `cluster1`.

```sh
kubectl apply -f install/online-boutique/web-ui.yaml
```

## Lab 5 - Configure Gloo Mesh Workspaces <a name="Lab-5"></a>


```yaml
kubectl apply -f - <<'EOF'
apiVersion: admin.gloo.solo.io/v2
kind: Workspace
metadata:
  name: ops-team
  namespace: gloo-mesh
spec:
  workloadClusters:
  - name: '*'
    namespaces:
    - name: ops-team
    - name: gloo-gateway
    - name: gloo-mesh-addons
---
apiVersion: admin.gloo.solo.io/v2
kind: Workspace
metadata:
  name: dev-team
  namespace: gloo-mesh
spec:
  workloadClusters:
  - name: '*'
    namespaces:
    - name: dev-team
    - name: web-ui
    - name: backend-apis
EOF
```

3. Apply the settings for each workspace. These `WorkspaceSettings` objects are used to tune each indiviual workspace as well as import/export resources from other workspaces. 

```sh
kubectl apply -f tracks/workspace-settings.yaml
```

The `WorkspaceSettings` custom resource lets each team define the services and gateways that they want other workspaces from other teams to be able to access. This way, you can control the discovery of services in your service mesh and enable each team to access only what they need.

Each workspace can have only one WorkspaceSettings resource.

## Lab 6 - Expose the Online Boutique <a name="Lab-6"></a>

```yaml
kubectl apply -f - <<'EOF'
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
        cluster: mgmt-cluster
        namespace: gloo-gateway
  listeners: 
    - http: {}
      port:
        number: 80
      allowedRouteTables:
        - host: '*'
          selector:
            workspace: ops-team
---
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: ingress
  namespace: ops-team
spec:
  hosts:
    - '*'
  virtualGateways:
    - name: north-south-gw
      namespace: ops-team
      cluster: mgmt-cluster
  workloadSelectors: []
  http:
    - name: dev-team-ingress
      labels:
        ingress: "true"
      delegate:
        routeTables:
        - workspace: dev-team
EOF
```


```yaml
kubectl apply -f - <<'EOF'
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: frontend
  namespace: dev-team
spec:
  workloadSelectors: []
  http:
    - matchers:
      - uri:
          prefix: /
      name: frontend
      labels:
        route: frontend
      forwardTo:
        destinations:
          - ref:
              name: frontend
              namespace: web-ui
              cluster: mgmt-cluster
            port:
              number: 80
EOF
```


## Lab 7 - Routing <a name="Lab-7"></a>


```yaml
kubectl apply -f - <<'EOF'
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: currency
  namespace: dev-team
spec:
  weight: 100
  workloadSelectors: []
  http:
    - matchers:
      - uri:
          prefix: /hipstershop.CurrencyService/Convert
      name: frontend
      labels:
        route: currency
      forwardTo:
        destinations:
          - ref:
              name: currencyservice
              namespace: backend-apis
              cluster: mgmt-cluster
            port:
              number: 7000
EOF
```

```sh
grpcurl --plaintext --proto ./install/online-boutique/online-boutique.proto -d '{ "from": { "currency_code": "USD", "nanos": 44637071, "units": "31" }, "to_code": "JPY" }' localhost:8080 hipstershop.CurrencyService/Convert

```

* Request

```json
{
    "from": {
        "currency_code": "USD",
        "nanos": 44637071,
        "units": "31"
    },
    "to_code": "JPY"
}
```

* Response 

```json
{
  "currencyCode": "JPY",
  "units": "3471",
  "nanos": 67780486
}
```



* External endpoint


```yaml
kubectl apply -f - <<'EOF'
apiVersion: networking.gloo.solo.io/v2
kind: ExternalEndpoint
metadata:
  name: httpbin
  namespace: dev-team
  labels:
    external-service: httpbin
spec:
  address: httpbin.org
  ports:
    - name: http
      number: 80
    - name: https
      number: 443
---
apiVersion: networking.gloo.solo.io/v2
kind: ExternalService
metadata:
  name: httpbin
  namespace: dev-team
spec:
  selector:
    external-service: httpbin
  hosts:
  - httpbin.org
  ports:
  - name: http
    number: 80
    protocol: HTTP
  - name: https
    number: 443
    protocol: HTTPS
---
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: httpbin
  namespace: dev-team
spec:
  weight: 150
  workloadSelectors: []
  http:
    - matchers:
      - uri:
          prefix: /httpbin
      name: frontend
      labels:
        route: httpbin
      forwardTo:
        pathRewrite: /
        destinations:
        - ref:
            name: httpbin
          port: 
            number: 80
          kind: EXTERNAL_SERVICE
EOF

```


TODO Grpc to json


## Lab 8 - Security <a name="Lab-8"></a>

* API Key
```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: httbin-team-1
  namespace: dev-team
  labels:
    api-keyset: httpbin-users
type: extauth.solo.io/apikey
data:
  api-key: TjJZd01ESXhaVEV0TkdVek5TMWpOemd6TFRSa1lqQXRZakUyWXpSa1pHVm1OamN5Cg==
EOF
```

```yaml
kubectl apply -f - <<EOF
apiVersion: security.policy.gloo.solo.io/v2
kind: ExtAuthPolicy
metadata:
  name: httpbin-apikey
  namespace: dev-team
spec:
  applyToRoutes:
  - route:
      labels:
        route: httpbin
  config:
    server:
      name: ext-auth-server
      namespace: gloo-addons
      cluster: mgmt-cluster
    glooAuth:
      configs:
      - apiKeyAuth:
          headerName: api-key
          labelSelector:
            api-keyset: httpbin-users
EOF
```


* JWT Token

```yaml
kubectl apply -f - <<EOF
apiVersion: networking.gloo.solo.io/v2
kind: ExternalEndpoint
metadata:
  name: auth0
  namespace: dev-team
  labels:
    external-service: auth0
spec:
  address: dev-64ktibmv.us.auth0.com
  ports:
    - name: https
      number: 443
---
apiVersion: networking.gloo.solo.io/v2
kind: ExternalService
metadata:
  name: auth0
  namespace: dev-team
spec:
  selector:
    external-service: auth0
  hosts:
  - dev-64ktibmv.us.auth0.com
  ports:
  - name: https
    number: 443
    protocol: HTTPS
---
apiVersion: security.policy.gloo.solo.io/v2
kind: JWTPolicy
metadata:
  name: curreny
  namespace: dev-team
spec:
  applyToRoutes:
  - route:
      labels:
        route: currency
  config:
    providers:
      auth0:
        issuer: "https://dev-64ktibmv.us.auth0.com/"
        audiences:
        - "https://httpbin/api"
        remote:
          url: "https://dev-64ktibmv.us.auth0.com/.well-known/jwks.json"
          destinationRef:
            ref:
              name: auth0
              namespace: dev-team
              cluster: mgmt-cluster
            kind: EXTERNAL_SERVICE
            port:
              number: 443
          enableAsyncFetch: true
EOF
```

```
AUTH_TOKEN=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Il82WUZwYko3YTVuWGI1RlZrUEJIYiJ9.eyJpc3MiOiJodHRwczovL2Rldi02NGt0aWJtdi51cy5hdXRoMC5jb20vIiwic3ViIjoiMVFFVmhaMkVScVpPcFRRbkhDaEsxVFVTS1JCZHVPNzJAY2xpZW50cyIsImF1ZCI6Imh0dHBzOi8vaHR0cGJpbi9hcGkiLCJpYXQiOjE2NTYxMDE4MzIsImV4cCI6MTY1NjE4ODIzMiwiYXpwIjoiMVFFVmhaMkVScVpPcFRRbkhDaEsxVFVTS1JCZHVPNzIiLCJzY29wZSI6InJlYWQ6bWVzc2FnZXMiLCJndHkiOiJjbGllbnQtY3JlZGVudGlhbHMifQ.su4tOBOOaKFevyImcqWVZA4P42cAbqFTxKILe1ilWpeEfRavcFJgHS0eoJ9ET3Y5Uudl9DVNSDT_-hrnHAJnQizAMYTXCyHSf9P8ltYeToToOEvJmbN7XGdluGgma0g25JW4V0A_E2fS33ZqrbmT0j0-H1jdByK4ShwuyecbrFdi_M5q3WbGt5Uzcr-UaHSQM5a2Y0rhedzRcDg2D3fCN8BnSVUGfqomeWBzY1Hg2-FG2sFbSUQFwVL9l6CFR7eCnXL6S1Aid9DndKvHhye7P6Mt8lkbQAtmLjVkNAytSg1CQPYmDpv0m79bHQVY5M3MRsrNxCDFd-nxwZ8XEZEo8w
grpcurl -H "Authorization: Bearer ${AUTH_TOKEN}"--plaintext --proto ./install/online-boutique/online-boutique.proto -d '{ "from": { "currency_code": "USD", "nanos": 44637071, "units": "31" }, "to_code": "JPY" }' localhost:8080 hipstershop.CurrencyService/Convert

```

* OIDC - Auth0/Keycloak?