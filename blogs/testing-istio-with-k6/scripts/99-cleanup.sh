# environment variables
#export MGMT=eks-lab1
#export CLUSTER1=eks-lab1

# Cleanup
kubectl --context ${MGMT} scale deployment -n gloo-mesh --replicas=0 --all
kubectl --context ${MGMT} scale deployment -n istio-gateways --replicas=0 --all
kubectl --context ${MGMT} scale deployment -n istio-system --replicas=0 --all
kubectl --context ${MGMT} delete istiooperator -l gloo.solo.io/parent_kind=GatewayLifecycleManager -A
kubectl --context ${MGMT} delete istiooperator -A --all
kubectl --context ${MGMT} wait --for=delete deployment -n istio-system --all --timeout=300s

#kubectl --context ${MGMT} get ns -oname | grep workspace- | xargs kubectl --context ${MGMT} delete
#kubectl --context ${MGMT} delete virtualgateways,routetables,wafpolicies,extauthpolicies -A --all

helm --kube-context ${MGMT} -n monitoring uninstall kube-prometheus-stack
helm --kube-context ${MGMT} -n logging uninstall loki
helm --kube-context ${MGMT} -n tracing uninstall tempo
helm --kube-context ${MGMT} -n gloo-mesh-addons uninstall gloo-platform
#kubectl --context ${MGMT} delete GatewayLifecycleManager -A --all
#kubectl --context ${MGMT} delete IstioLifecycleManager -A --all
helm --kube-context ${MGMT} -n gloo-mesh uninstall gloo-platform
helm --kube-context ${MGMT} -n gloo-mesh uninstall gloo-platform-crds

kubectl --context ${MGMT} get crd -oname | grep --color=never 'solo' | xargs kubectl --context ${MGMT} delete
kubectl --context ${CLUSTER1} get crd -oname | grep --color=never 'solo' | xargs kubectl --context ${CLUSTER1} delete
kubectl --context ${CLUSTER1} get crd -oname | grep --color=never 'istio' | xargs kubectl --context ${CLUSTER1} delete
kubectl --context ${CLUSTER1} get crd -oname | grep --color=never 'monitoring' | xargs kubectl --context ${CLUSTER1} delete

kubectl --context ${CLUSTER1} delete ns logging monitoring tracing k6 gloo-mesh-addons gloo-mesh istio-gateways istio-system
kubectl --context ${MGMT} get ns -oname | grep workspace- | xargs kubectl --context ${MGMT} delete
kubectl --context ${MGMT} delete ns gloo-mesh
kubectl --context ${MGMT} delete ns -l gloo.solo.io/parent_version=v2
