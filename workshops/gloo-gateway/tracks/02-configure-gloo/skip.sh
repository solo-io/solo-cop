#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Deploy apps
kubectl apply -f $LOCAL_DIR/../../install/online-boutique/backend-apis.yaml

kubectl apply -f $LOCAL_DIR/../../install/online-boutique/online-boutique.yaml

# Deploy workspaces
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
    - name: ops-team     ### Configuration Namespace
    - name: gloo-gateway
    - name: gloo-gateway-addons
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
    - name: dev-team  ### Configuration Namespace
    - name: online-boutique
    - name: backend-apis
EOF

# Workspace settings


kubectl apply -f $LOCAL_DIR/../../tracks/workspace-settings.yaml

# Gateway
kubectl apply -f - <<'EOF'
apiVersion: networking.gloo.solo.io/v2
kind: VirtualGateway
metadata:
  name: north-south-gw
  namespace: gloo-mesh-gateways
spec:
  workloads:
    - selector:
        labels:
          app: istio-ingressgateway
        namespace: gloo-mesh-gateways
  listeners:
    - http: {}
      port:
        number: 80
      allowedRouteTables:
        - host: '*'
          selector:
            workspace: ops-team
EOF

kubectl apply -f - <<'EOF'
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: ingress
  namespace: gloo-mesh-gateways
spec:
  hosts:
    - '*'
  virtualGateways:
    - name: north-south-gw
      namespace: gloo-mesh-gateways
  workloadSelectors: []
  http:
    - name: dev-team-ingress
      labels:
        ingress: "true"
      delegate:
        routeTables:
        - workspace: dev-team
EOF

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
              namespace: online-boutique
            port:
              number: 80
EOF

# SSL
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
   -keyout tls.key -out tls.crt -subj "/CN=*"

kubectl -n gloo-gateway create secret generic tls-secret \
--from-file=tls.key=tls.key \
--from-file=tls.crt=tls.crt

# Virtual gateway
kubectl apply -f - <<'EOF'
apiVersion: networking.gloo.solo.io/v2
kind: VirtualGateway
metadata:
  name: north-south-gw
  namespace: gloo-mesh-gateways
  labels:
    ingress: ssl-enabled
spec:
  workloads:
    - selector:
        labels:
          istio: ingressgateway
        namespace: gloo-gateway
  listeners:
    - http: {}
      port:
        number: 80
    - http: {}
      port:
        number: 443
      tls:
        mode: SIMPLE
        secretName: tls-secret # NOTE
      allowedRouteTables:
        - host: '*'
          selector:
            workspace: ops-team
EOF