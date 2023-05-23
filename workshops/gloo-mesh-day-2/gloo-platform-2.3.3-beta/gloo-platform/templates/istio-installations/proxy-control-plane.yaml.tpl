{{/* Installs the Istio Control Plane via the Gloo Mesh Istio Lifecycle Management feature. */}}
{{- define "controlPlane.iopSpec" }}
profile: minimal
{{/* TODO: support custom istio namespace */}}
{{/*namespace: {{ .Release.Namespace }}-gateways*/}}
namespace: istio-system
meshConfig:
  # enable access logging to standard output
  accessLogFile: /dev/stdout

  defaultConfig:
    # wait for the istio-proxy to start before application pods
    holdApplicationUntilProxyStarts: true
    # enable Gloo Mesh metrics service (required for Goo Mesh UI)
    envoyMetricsService:
      address: gloo-mesh-agent.{{ $.Release.Namespace }}:9977
      # enable GlooMesh accesslog service (required for Gloo Mesh Access Logging)
    envoyAccessLogService:
      address: gloo-mesh-agent.{{ $.Release.Namespace }}:9977
    proxyMetadata:
      # Enable Istio agent to handle DNS requests for known hosts
      # Unknown hosts will automatically be resolved using upstream dns servers in resolv.conf
      # (for proxy-dns)
      ISTIO_META_DNS_CAPTURE: "true"
      # Enable automatic address allocation (for proxy-dns)
      ISTIO_META_DNS_AUTO_ALLOCATE: "true"

  # Set the default behavior of the sidecar for handling outbound traffic from the application.
  outboundTrafficPolicy:
    mode: ALLOW_ANY
  # The trust domain corresponds to the trust root of a system.
  # For Gloo Mesh this should be the name of the cluster that corresponds with the CA certificate CommonName identity
  trustDomain: {{ $.Values.common.cluster }}
components:
  pilot:
    k8s:
      env:
        # Allow multiple trust domains (Required for Gloo Mesh east/west routing)
        - name: PILOT_SKIP_VALIDATE_TRUST_DOMAIN
          value: "true"
values:
  global:
{{/* TODO: support custom istio namespace   istioNamespace: {{ $.Release.Namespace }}*/}}
{{/*    # install istio to the release namespace by default*/}}
    # needed for connecting VirtualMachines to the mesh
    network: {{ $.Values.common.cluster }}
    # needed for annotating istio metrics with cluster (should match trust domain)
    multiCluster:
      clusterName: {{ $.Values.common.cluster }}
{{- end }} {{/* define "controlPlane.iopSpec" */}}

