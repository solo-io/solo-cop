{{/* Installs any EW Gateways via the Gloo Mesh Istio Lifecycle Management feature. */}}
{{- define "eastWestGateways.iopSpec" }}
profile: empty
{{/* TODO: support custom istio namespace */}}
{{/*namespace: {{ .Release.Namespace }}-gateways*/}}
namespace: istio-system
components:
  ingressGateways:
    # enable a default ew gateway
    - name: {{ .gateway.name }}
      enabled: true
      namespace: {{ .Release.Namespace }}-gateways
      label:
        istio: eastwestgateway-{{ .gateway.name }}
      k8s:
        env:
          # sni-dnat adds the clusters required for AUTO_PASSTHROUGH mode
          # Required by Gloo Mesh for east/west routing
          - name: ISTIO_META_ROUTER_MODE
            value: "sni-dnat"
        service:
          type: LoadBalancer
          selector:
            istio: eastwestgateway-{{ .gateway.name }}
          # Default ports
          ports:
            # Health check port. For AWS ELBs, this port must be listed first.
            - name: status-port
              port: 15021
              targetPort: 15021
            # Port for multicluster mTLS passthrough; required for Gloo Mesh east/west routing
            - port: 15443
              targetPort: 15443
              # Gloo Mesh looks for this default name 'tls' on a gateway
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
{{- end }} {{/* define "eastWestGateways.iopSpec" */}}

