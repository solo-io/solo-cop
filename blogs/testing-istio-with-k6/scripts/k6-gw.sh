kubectl --context ${MGMT} delete gatewaylifecyclemanagers.admin.gloo.solo.io -A --all
kubectl apply --context ${MGMT} -f - <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: GatewayLifecycleManager
metadata:
  name: cluster1-ingress-${CPU}
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
                    cpu: ${CPU}
                    memory: ${MEMORY}
                  requests:
                    cpu: ${CPU}
                    memory: ${MEMORY}
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
                  - path: spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms
                    value:
                    - matchExpressions:
                      - key: node.kubernetes.io/instance-type
                        operator: In
                        values:
                        - c5.4xlarge
EOF
