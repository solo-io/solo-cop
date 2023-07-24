# environment variables
#export MGMT=eks-lab1
#export CLUSTER1=eks-lab1
#export GLOO_PLATFORM_VERSION=2.4.0-beta0-2023-05-08-main-f30afbc65
#export GLOO_PLATFORM_VERSION=2.4.0-beta1-2023-05-24-eitanya-tracing-main-99de25c9c
export GLOO_PLATFORM_VERSION=2.4.0-beta1-2023-06-15-eitanya-tracing-main-5d88ab5b5

helm repo add gloo-platform https://storage.googleapis.com/gloo-platform/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

# Install Gloo Platform CRDs
kubectl --context ${MGMT} create ns gloo-mesh
helm upgrade --install gloo-platform-crds https://storage.googleapis.com/gloo-platform-dev/platform-charts/helm-charts/gloo-platform-crds-$GLOO_PLATFORM_VERSION.tgz \
--namespace gloo-mesh \
--kube-context ${MGMT} \
--version ${GLOO_PLATFORM_VERSION}

# Install Gloo Platform
helm upgrade --install gloo-platform https://storage.googleapis.com/gloo-platform-dev/platform-charts/helm-charts/gloo-platform-$GLOO_PLATFORM_VERSION.tgz \
--namespace gloo-mesh \
--kube-context ${MGMT} \
--version ${GLOO_PLATFORM_VERSION} \
 -f -<<EOF
licensing:
  licenseKey: ${GLOO_MESH_LICENSE_KEY}
common:
  cluster: cluster1
glooMgmtServer:
  enabled: true
  verbose: true
  service:
    type: ClusterIP
  ports:
    healthcheck: 8091
  resources:
    requests:
        cpu: 2500m
        memory: 10Gi
    limits:
        cpu: 7500m
        memory: 24Gi
  deploymentOverrides:
    spec:
      template:
        spec:
          topologySpreadConstraints:
          - maxSkew: 1
            topologyKey: kubernetes.io/hostname
            whenUnsatisfiable: DoNotSchedule
            labelSelector:
              matchLabels:
                app: gloo-mesh-mgmt-server
          tolerations:
          - key: gloo-mgmt
            operator: Exists
            effect: NoSchedule
          affinity:
            nodeAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                nodeSelectorTerms:
                - matchExpressions:
                  - key: node-restriction.kubernetes.io/gloo-mgmt
                    operator: Exists
prometheus:
  enabled: true
  server:
    persistentVolume:
      enabled: true
      existingClaim: prometheus-server
redis:
  deployment:
    enabled: true
glooUi:
  enabled: true
telemetryGateway:
  enabled: true
  service:
    type: ClusterIP
  image:
    repository: gcr.io/solo-test-236622/gloo-platform-dev/gloo-otel-collector
glooAgent:
  enabled: true
  relay:
    serverAddress: gloo-mesh-mgmt-server:9900
    authority: gloo-mesh-mgmt-server.gloo-mesh
telemetryCollector:
  enabled: true
  config:
    exporters:
      otlp:
        endpoint: gloo-telemetry-gateway:4317
  image:
    repository: gcr.io/solo-test-236622/gloo-platform-dev/gloo-otel-collector
telemetryCollectorCustomization:
  extraProcessors:
    batch/istiod:
      send_batch_size: 10000
      timeout: 10s
    filter/istiod:
      metrics:
        include:
          match_type: regexp
          metric_names:
            - "pilot.*"
            - "process.*"
            - "go.*"
            - "container.*"
            - "envoy.*"
            - "galley.*"
            - "sidecar.*"
  extraPipelines:
    metrics/istiod:
      receivers:
      - prometheus
      processors:
      - memory_limiter
      - batch/istiod
      - filter/istiod
      exporters:
      - otlp
EOF
kubectl apply --context ${MGMT} -f- <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: KubernetesCluster
metadata:
  name: cluster1
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
EOF

kubectl --context $CLUSTER1 -n gloo-mesh get cm gloo-telemetry-collector-config -oyaml | sed "/- attributes\/drop_extra_istio_labels/d" | kubectl --context $CLUSTER1 apply -f -
kubectl --context $CLUSTER1 -n gloo-mesh rollout restart ds/gloo-telemetry-collector-agent

# Install Istio
kubectl --context ${CLUSTER1} create ns istio-gateways
kubectl --context ${CLUSTER1} label namespace istio-gateways istio.io/rev=1-18 --overwrite
kubectl apply --context ${CLUSTER1} -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: istio-ingressgateway
    istio: ingressgateway
  name: istio-ingressgateway
  namespace: istio-gateways
spec:
  ports:
  - name: http2
    port: 80
    protocol: TCP
    targetPort: 8080
  - name: https
    port: 443
    protocol: TCP
    targetPort: 8443
  selector:
    app: istio-ingressgateway
    istio: ingressgateway
    revision: 1-18
  type: ClusterIP
EOF

kubectl apply --context ${MGMT} -f - <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: IstioLifecycleManager
metadata:
  name: cluster1-installation
  namespace: gloo-mesh
spec:
  installations:
    - clusters:
      - name: cluster1
        defaultRevision: true
      revision: 1-18
      istioOperatorSpec:
        profile: minimal
        hub: us-docker.pkg.dev/gloo-mesh/istio-workshops
        tag: 1.18.0-solo
        namespace: istio-system
        values:
          global:
            meshID: mesh1
            multiCluster:
              clusterName: cluster1
            network: cluster1
        meshConfig:
          accessLogFile: /dev/stdout
          defaultConfig:        
            proxyMetadata:
              ISTIO_META_DNS_CAPTURE: "true"
              ISTIO_META_DNS_AUTO_ALLOCATE: "true"
        components:
          pilot:
            k8s:
              env:
                - name: PILOT_ENABLE_K8S_SELECT_WORKLOAD_ENTRIES
                  value: "false"
              resources:
                limits:
                  cpu: 4000m
                  memory: 20Gi
                requests:
                  cpu: 2000m
                  memory: 10Gi
              hpaSpec:
                maxReplicas: 10
                minReplicas: 1
              overlays:
              - apiVersion: apps/v1
                kind: Deployment
                name: istiod-1-18
                patches:
                - path: spec.template.spec.topologySpreadConstraints
                  value:
                  - maxSkew: 1
                    topologyKey: kubernetes.io/hostname
                    whenUnsatisfiable: DoNotSchedule
                    labelSelector:
                      matchLabels:
                        istio: istiod
          ingressGateways:
          - name: istio-ingressgateway
            enabled: false
EOF
kubectl apply --context ${MGMT} -f - <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: GatewayLifecycleManager
metadata:
  name: cluster1-ingress
  namespace: gloo-mesh
spec:
  installations:
    - clusters:
      - name: cluster1
        activeGateway: false
      gatewayRevision: 1-18
      istioOperatorSpec:
        profile: empty
        hub: us-docker.pkg.dev/gloo-mesh/istio-workshops
        tag: 1.18.0-solo
        values:
          gateways:
            istio-ingressgateway:
              customService: true
        components:
          ingressGateways:
            - name: istio-ingressgateway
              namespace: istio-gateways
              enabled: true
              label:
                istio: ingressgateway
              k8s:
                resources:
                  limits:
                    cpu: 8000m
                    memory: 32Gi
                  requests:
                    cpu: 2000m
                    memory: 16Gi
                hpaSpec:
                  maxReplicas: 1
                  minReplicas: 1
                overlays:
                - apiVersion: apps/v1
                  kind: Deployment
                  name: istio-ingressgateway-1-18
                  patches:
                  - path: spec.template.spec.topologySpreadConstraints
                    value:
                    - maxSkew: 1
                      topologyKey: kubernetes.io/hostname
                      whenUnsatisfiable: DoNotSchedule
                      labelSelector:
                        matchLabels:
                          istio: ingressgateway
                  - path: spec.template.spec.tolerations
                    value:
                    - key: ingress
                      operator: Exists
                      effect: NoSchedule
                  # - path: spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms
                  #   value:
                  #   - matchExpressions:
                  #     - key: node.kubernetes.io/instance-type
                  #       operator: In
                  #       values:
                  #       - c5.4xlarge
EOF

# Install Addons
kubectl --context ${CLUSTER1} create namespace gloo-mesh-addons
kubectl --context ${CLUSTER1} label namespace gloo-mesh-addons istio.io/rev=1-18 --overwrite
helm upgrade --install gloo-platform https://storage.googleapis.com/gloo-platform-dev/platform-charts/helm-charts/gloo-platform-$GLOO_PLATFORM_VERSION.tgz \
  --namespace gloo-mesh-addons \
  --kube-context=${CLUSTER1} \
  --version ${GLOO_PLATFORM_VERSION} \
 -f -<<EOF
common:
  cluster: cluster1
glooPortalServer:
  enabled: false
  apiKeyStorage:
    config:
      host: redis.gloo-mesh-addons:6379
    configPath: /etc/redis/config.yaml
    secretKey: ThisIsSecret
extAuthService:
  enabled: true
  extAuth: 
    apiKeyStorage: 
      name: redis
      config: 
        connection: 
          host: redis.gloo-mesh-addons:6379
      secretKey: ThisIsSecret
    image:
      registry: gcr.io/gloo-mesh
    resources:
      requests:
        cpu: 2500m
        memory: 1Gi
rateLimiter:
  enabled: true
  rateLimiter:
    image:
      registry: gcr.io/gloo-mesh
EOF

kubectl --context ${CLUSTER1} -n gloo-mesh-addons patch deployment ext-auth-service --patch-file /dev/stdin <<EOF
spec:
  template:
    spec:
      affinity:
        # podAffinity:
        #   requiredDuringSchedulingIgnoredDuringExecution:
        #   - labelSelector:
        #       matchExpressions:
        #       - key: istio
        #         operator: In
        #         values:
        #         - ingressgateway
        #     topologyKey: kubernetes.io/hostname
        #     namespaces:
        #     - istio-gateways
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node.kubernetes.io/instance-type
                operator: In
                values:
                - c5.4xlarge
      tolerations:
      - key: ingress
        operator: Exists
        effect: NoSchedule
EOF

kubectl apply --context ${MGMT} -f - <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: Workspace
metadata:
  name: gateways
  namespace: gloo-mesh
spec:
  workloadClusters:
  - name: cluster1
    namespaces:
    - name: istio-gateways
    - name: gloo-mesh-addons
EOF
kubectl apply --context ${CLUSTER1} -f - <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: WorkspaceSettings
metadata:
  name: gateways
  namespace: istio-gateways
spec:
  importFrom:
  - workspaces:
    - selector:
        allow_ingress: "true"
    resources:
    - kind: SERVICE
    - kind: ALL
      labels:
        expose: "true"
  exportTo:
  - workspaces:
    - selector:
        allow_ingress: "true"
    resources:
    - kind: SERVICE
EOF

# Install Observability
helm upgrade --install loki grafana/loki-stack \
--version 2.9.9 \
--namespace logging \
--create-namespace

helm upgrade --install tempo grafana/tempo \
--kube-context ${MGMT} \
--version 1.0.2 \
--namespace tracing \
--create-namespace \
--values - <<EOF
tempo:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
    jaeger:
      protocols:
        thrift_http:
          endpoint: 0.0.0.0:14268
EOF

# kubectl apply --context ${CLUSTER1} -f - <<EOF
# apiVersion: v1
# kind: Service
# metadata:
#   name: tempo-headless
#   namespace: tracing
# spec:
#   ports:
#   - port: 14268
#     name: tempo-jaeger-thrift-http
#   clusterIP: None
#   selector:
#     app.kubernetes.io/instance: tempo
#     app.kubernetes.io/name: tempo
# EOF

helm upgrade --install kube-prometheus-stack \
prometheus-community/kube-prometheus-stack \
--kube-context ${MGMT} \
--version 44.3.1 \
--namespace monitoring \
--create-namespace \
--values - <<EOF
prometheus:
  prometheusSpec:
    enableRemoteWriteReceiver: true
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp2
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 20Gi
grafana:
  env:
    GF_FEATURE_TOGGLES_ENABLE: tempoSearch,tempoServiceGraph,tempoApmTable,traceqlEditor
  service:
    type: LoadBalancer
    port: 3000
  additionalDataSources:
  - name: prometheus-GM
    uid: prometheus-GM
    type: prometheus
    url: http://prometheus-server.gloo-mesh:80
  - name: Loki
    type: loki
    url: http://loki.logging.svc.cluster.local:3100
    jsonData:
      maxLines: 2000
  - name: Tempo
    type: tempo
    access: proxy
    orgId: 1
    url: http://tempo.tracing.svc.cluster.local:3100
    basicAuth: false
    version: 1
    editable: false
    apiVersion: 1
    uid: tempo
EOF

helm upgrade --install traces-otel-collector \
open-telemetry/opentelemetry-collector \
--kube-context ${MGMT} \
--version 0.59.2 \
--namespace tracing \
--create-namespace \
--values - <<EOF
mode: deployment
resources:
  limits:
    cpu: 2
    memory: 4Gi
config:
  receivers:
    jaeger:
      protocols:
        thrift_http:
          endpoint: 0.0.0.0:14268
  exporters:
    otlp:
      endpoint: tempo.tracing.svc.cluster.local:4317
      tls:
        insecure: true
  processors:
    tail_sampling:
      decision_wait: 30s
      num_traces: 1
      expected_new_traces_per_sec: 10
      policies:
        [
            {
              name: test-policy-1,
              type: always_sample
            }
        ]
  service:
    pipelines:
      traces:
        receivers:
          - jaeger
        # processors:
        #   - tail_sampling
        exporters:
          - otlp
      metrics: null
      logs: null
EOF

kubectl --context ${CLUSTER1} set env deploy -n gloo-mesh gloo-mesh-mgmt-server HISTOGRAM_BUCKET_RATIO="60.0" EXPERIMENTAL_SEGMENT_ENVOY_FILTERS_BY_MATCHER="true" OTEL_EXPORTER_JAEGER_ENDPOINT="http://$(kubectl --context ${CLUSTER1} -n tracing get svc tempo -ojson | jq -r .spec.clusterIP):14268/api/traces"
kubectl --context ${CLUSTER1} set env deploy -n gloo-mesh gloo-mesh-agent HISTOGRAM_BUCKET_RATIO="60.0"
#kubectl --context ${CLUSTER1} set env deploy -n gloo-mesh gloo-mesh-mgmt-server FEATURE_SEGMENT_ENVOY_FILTERS_BY_MATCHER="true" OTEL_EXPORTER_JAEGER_ENDPOINT="http://$(kubectl --context ${CLUSTER1} -n tracing get svc traces-otel-collector-opentelemetry-collector -ojson | jq -r .spec.clusterIP):14268/api/traces"

kubectl --context ${CLUSTER1} -n monitoring delete cm istio-dashboards
kubectl --context ${CLUSTER1} -n monitoring create cm istio-dashboards \
--from-file=gloo-platform-dashboard.json=dashboards/gloo-platform-dashboard.json \
--from-file=istio-custom-dashboard.json=dashboards/istio-custom.json \
--from-file=pilot-dashboard.json=dashboards/pilot-dashboard.json \
--from-file=istio-workload-dashboard.json=dashboards/istio-workload-dashboard.json \
--from-file=istio-service-dashboard.json=dashboards/istio-service-dashboard.json \
--from-file=istio-mesh-dashboard.json=dashboards/istio-mesh-dashboard.json \
--from-file=istio-performance-dashboard.json=dashboards/istio-performance-dashboard.json \
--from-file=k6-test-result_rev2.json=dashboards/k6-test-result_rev2.json
kubectl --context ${CLUSTER1} label -n monitoring cm istio-dashboards grafana_dashboard=1

## Deploy k6
kubectl --context ${CLUSTER1} create ns k6

kubectl --context ${CLUSTER1} delete configmap k6-test -n k6
kubectl --context ${CLUSTER1} create configmap k6-test --from-file k6-test.js --from-file k6-test-single.js --from-file k6-test-quick.js  -n k6
kubectl --context ${CLUSTER1} delete -f k6-runner.yaml -n k6
kubectl --context ${CLUSTER1} apply -f k6-runner.yaml -n k6