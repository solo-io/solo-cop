# Automatic Cert Rotation with cert-manager



## Install Gloo Mesh

```sh
export GLOO_MESH_VERSION=v2.1.2

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

kubectl create namespace istio-system --context ${CLUSTER1}
kubectl create namespace istio-system --context ${CLUSTER2}

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.10.1/cert-manager.yaml --context ${CLUSTER1}
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.10.1/cert-manager.yaml --context ${CLUSTER2}

kubectl create secret generic ca-key-pair \
  --from-file=tls.key=root-key.pem \
  --from-file=tls.crt=root-cert.pem \
  --context $CLUSTER1 \
  --namespace istio-system

kubectl create secret generic ca-key-pair \
  --from-file=tls.key=root-key.pem \
  --from-file=tls.crt=root-cert.pem \
  --context $CLUSTER2 \
  --namespace istio-system

cat << EOF | kubectl --context ${CLUSTER1} apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: ca-issuer
  namespace: istio-system
spec:
  ca:
    secretName: ca-key-pair
EOF

cat << EOF | kubectl --context ${CLUSTER2} apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: ca-issuer
  namespace: istio-system
spec:
  ca:
    secretName: ca-key-pair
EOF


kubectl apply --context $CLUSTER1 -f- <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cluster1-cacerts
  namespace: istio-system
spec:
  secretName: cacerts
  duration: 720h # 30d
  renewBefore: 360h # 15d
  commonName: cluster1-3.solo.io
  isCA: true
  usages:
    - digital signature
    - key encipherment
    - cert sign
  dnsNames:
    - cluster1-3.solo.io
  issuerRef:
    kind: Issuer
    name: ca-issuer
EOF


kubectl apply --context $CLUSTER2 -f- <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cluster2-cacerts
  namespace: istio-system
spec:
  secretName: cacerts
  duration: 720h # 30d
  renewBefore: 360h # 15d
  commonName: cluster2.solo.io
  isCA: true
  usages:
    - digital signature
    - key encipherment
    - cert sign
  dnsNames:
    - cluster2.solo.io
  issuerRef:
    kind: Issuer
    name: ca-issuer
EOF

kubectl create namespace ops-team --context $MGMT
kubectl create namespace web-team --context $MGMT
kubectl create namespace backend-apis-team --context $MGMT
kubectl apply -f workspaces.yaml --context $MGMT

kubectl create namespace web-ui --context $CLUSTER2
kubectl label ns web-ui istio-injection=enabled --context $CLUSTER2
kubectl apply -n web-ui --context $CLUSTER2 -f cluster2-apps.yaml

kubectl apply -f istio-install.yaml --context $MGMT


```

```
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

```
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