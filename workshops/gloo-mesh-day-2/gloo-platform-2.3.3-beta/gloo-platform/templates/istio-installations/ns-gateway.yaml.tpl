{{/* Installs any NS Gateways via the Gloo Mesh Istio Lifecycle Management feature. */}}
{{- define "northSouthGateways.iopSpec" }}
profile: empty
{{/* TODO: support custom istio namespace */}}
{{/*namespace: {{ .Release.Namespace }}-gateways*/}}
namespace: istio-system
components:
  ingressGateways:
    # enable a default ns gateway
    - name: {{ .gateway.name }}
      enabled: true
      namespace: {{ .Release.Namespace }}-gateways
      k8s:
        service:
          type: LoadBalancer
          ports:
            # health check port (required to be first for aws elbs)
            - name: status-port
              port: 15021
              targetPort: 15021
            # main http ingress port
            - port: 80
              targetPort: 8080
              name: http2
            # main https ingress port
            - port: 443
              targetPort: 8443
              name: https
            # Port for gloo-mesh multi-cluster mTLS passthrough (Required for Gloo Mesh east/west routing)
            - port: 15443
              targetPort: 15443
              # Gloo Mesh looks for this default name 'tls' on an ingress gateway
              name: tls
values:
  # https://istio.io/v1.5/docs/reference/config/installation-options/#global-options
  global:
{{/* TODO: support custom istio namespace   istioNamespace: {{ $.Release.Namespace }}*/}}
{{/*    # install istio to the release namespace by default*/}}
    istioNamespace: istio-system
    # needed for connecting VirtualMachines to the mesh
    network: {{ $.Values.common.cluster }}
    # needed for annotating istio metrics with cluster (should match trust domain)
    multiCluster:
      clusterName: {{ $.Values.common.cluster }}
{{- end }} {{/* define "northSouthGateways.iopSpec" */}}
