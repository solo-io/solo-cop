NWORKSPACES=$1
NDOMAINS=$2
NPATHS=$3
SUFFIX=$4

NWORKSPACES=${NWORKSPACES:-5}
NDOMAINS=${NDOMAINS:-10}
NPATHS=${NPATHS:-10}

rm -f mgmt${SUFFIX} cluster1${SUFFIX} mgmt-${SUFFIX} cluster1-${SUFFIX}

for workspace in $(seq 1 $NWORKSPACES); do
printf "\nworkspace-${workspace}."

cat << EOF >> mgmtv3
apiVersion: admin.gloo.solo.io/v2
kind: Workspace
metadata:
  name: workspace-${workspace}
  namespace: gloo-mesh
  labels:
    allow_ingress: "true"
spec:
  workloadClusters:
  - name: cluster1
    namespaces:
    - name: workspace-${workspace}
---
EOF
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
   -keyout tlsv3.key -out tlsv3.crt -subj "/CN=*/O=workspace-${workspace}" >/dev/null 2>&1

cat << EOF >> cluster1v3
apiVersion: v1
kind: Namespace
metadata:
  labels:
    istio.io/rev: 1-17
    subset: phase1
    workspace: workspace-${workspace}
  name: workspace-${workspace}
spec: {}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    subset: app
    workspace: workspace-${workspace}
  name: echoenv
  namespace: workspace-${workspace}
---
apiVersion: v1
kind: Service
metadata:
  labels:
    subset: app
    workspace: workspace-${workspace}
    app: echoenv
    service: echoenv
  name: echoenv
  namespace: workspace-${workspace}
spec:
  ports:
    - name: http
      port: 8000
      targetPort: 8080
      protocol: TCP
  selector:
    app: echoenv
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    subset: app
    workspace: workspace-${workspace}
  name: echoenv
  namespace: workspace-${workspace}
spec:
  replicas: 0
  selector:
    matchLabels:
      app: echoenv
      version: v1
  template:
    metadata:
      labels:
        app: echoenv
        version: v1
    spec:
      serviceAccountName: echoenv
      containers:
        - name: echoenv
          image: quay.io/simonkrenger/echoenv
          ports:
            - name: http
              containerPort: 8080
          resources:
            requests:
              cpu: 2000m
              memory: 1Gi
---
apiVersion: admin.gloo.solo.io/v2
kind: WorkspaceSettings
metadata:
  labels:
    subset: phase1
    workspace: workspace-${workspace}
  name: workspace-${workspace}
  namespace: workspace-${workspace}
spec:
  importFrom:
  - workspaces:
    - name: gateways
    resources:
    - kind: SERVICE
  exportTo:
  - workspaces:
    - name: gateways
    resources:
    - kind: SERVICE
    - kind: ALL
      labels:
        expose: "true"
---
apiVersion: admin.gloo.solo.io/v2
kind: ExtAuthServer
metadata:
  labels:
    subset: phase1
    workspace: workspace-${workspace}
  name: ext-auth-server
  namespace: workspace-${workspace}
spec:
  destinationServer:
    ref:
      cluster: cluster1
      name: ext-auth-service
      namespace: gloo-mesh-addons
    port:
      name: grpc
---
apiVersion: v1
kind: Secret
metadata:
  name: user1
  namespace: workspace-${workspace}
  labels:
    workspace: workspace-${workspace}
    subset: phase1
    extauth: apikey
type: extauth.solo.io/apikey
data:
  api-key: $(echo -n N2YwMDIxZTEtNGUzNS1jNzgzLTRkYjAtYjE2YzRkZGVmNjcy | base64)
  user-id: $(echo -n user1 | base64)
  user-email: $(echo -n user1@example.com | base64)
---
apiVersion: security.policy.gloo.solo.io/v2
kind: ExtAuthPolicy
metadata:
  labels:
    workspace: workspace-${workspace}
    subset: phase1
  name: apikey
  namespace: workspace-${workspace}
spec:
  applyToRoutes:
  - route:
      labels:
        apikey: "true"
  config:
    server:
      name: ext-auth-server
      namespace: workspace-${workspace}
      cluster: cluster1
    glooAuth:
      configs:
      - apiKeyAuth:
          headerName: api-key
          headersFromMetadataEntry:
            x-user-email: 
              name: user-email
          labelSelector:
            extauth: apikey
---
apiVersion: security.policy.gloo.solo.io/v2
kind: WAFPolicy
metadata:
  labels:
    workspace: workspace-${workspace}
    subset: phase1
  name: waf
  namespace: workspace-${workspace}
spec:
  applyToRoutes:
  - route:
      labels:
        waf: "true"
  config:
    requestHeadersOnly: true
    customInterventionMessage: custom-intervention-message
    customRuleSets:
    - ruleStr: |
        SecRuleEngine On
        SecRule REQUEST_HEADERS:User-Agent "test([1-5])$" "deny,status:403,id:1,phase:1,msg:'blocked scammer'"
    disableCoreRuleSet: true
    priority: 0
---
apiVersion: v1
kind: Secret
metadata:
  labels:
    workspace: workspace-${workspace}
    subset: phase2
  name: wrk-${workspace}
  namespace: istio-gateways
type: Opaque
data:
  tls.crt: $(cat tlsv3.crt | base64)
  tls.key: $(cat tlsv3.key | base64)
---
apiVersion: networking.gloo.solo.io/v2
kind: VirtualGateway
metadata:
  labels:
    workspace: workspace-${workspace}
    subset: phase3
  name: wrk-${workspace}
  namespace: istio-gateways
spec:
  workloads:
    - selector:
        labels:
          istio: ingressgateway
          #subset: shard-$(($workspace % 10))
        cluster: cluster1
  listeners:
EOF

for domain in $(seq 1 $NDOMAINS); do
cat << EOF >> cluster1v3
    - http: {}
      port:
        number: 443
      tls:
        mode: SIMPLE
        secretName: wrk-${workspace}
      allowedRouteTables:
      - host: workspace-${workspace}-domain-${domain}.com
EOF
done
cat << EOF >> cluster1v3
---
EOF

for domain in $(seq 1 $NDOMAINS); do
printf "${domain}."
cat << EOF >> cluster1v3
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  labels:
    workspace: workspace-${workspace}
    domain: domain-${domain}
    subset: phase3
  name: wrk-${workspace}-dom-${domain}
  namespace: istio-gateways
spec:
  hosts:
    - workspace-${workspace}-domain-${domain}.com
  virtualGateways:
    - name: wrk-${workspace}
      namespace: istio-gateways
      cluster: cluster1
  workloadSelectors: []
  http:
    - name: echoenv
      labels:
        apikey: "true"
        waf: "true"
      matchers:
EOF
for i in $(seq 1 $NPATHS); do
cat << EOF >> cluster1v3
      - uri:
          exact: /get/$i
EOF
done
cat << EOF >> cluster1v3
      forwardTo:
        pathRewrite: /
        destinations:
        - ref:
            name: echoenv
            namespace: workspace-${workspace}
          port:
            number: 8000
---
EOF

done
done

mv mgmtv3 mgmt-${SUFFIX}
mv cluster1v3 cluster1-${SUFFIX}