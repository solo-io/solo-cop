kubectl --context ${MGMT}  apply -f ../scenarios/mgmt-5w-100d-100p --server-side=true --force-conflicts=true
kubectl --context ${CLUSTER1} apply -f ../scenarios/cluster1-5w-100d-100p --server-side=true --force-conflicts=true

# For the first 4 workspaces (the ones used in tests), disable WAF and API Key
# workspace-1 have no filters
# workspace-2 have only waf
# workspace-3 have only extauth/apikey
# workspace-4 have both extauth/apikey and waf
kubectl --context ${MGMT} get wafpolicy -n workspace-1 -oyaml|sed 's/waf: .*/waf: "disabled"/'|kubectl --context ${MGMT} apply -f -
kubectl --context ${MGMT} get wafpolicy -n workspace-3 -oyaml|sed 's/waf: .*/waf: "disabled"/'|kubectl --context ${MGMT} apply -f -
kubectl --context ${MGMT} get ExtAuthPolicy -n workspace-1 -oyaml|sed 's/apikey: .*/apikey: "disabled"/'|kubectl --context ${MGMT} apply -f -
kubectl --context ${MGMT} get ExtAuthPolicy -n workspace-2 -oyaml|sed 's/apikey: .*/apikey: "disabled"/'|kubectl --context ${MGMT} apply -f -

# scale the app before the test
kubectl --context ${CLUSTER1} -n workspace-1 scale deploy echoenv --replicas=3
kubectl --context ${CLUSTER1} -n workspace-2 scale deploy echoenv --replicas=3
kubectl --context ${CLUSTER1} -n workspace-3 scale deploy echoenv --replicas=3
kubectl --context ${CLUSTER1} -n workspace-4 scale deploy echoenv --replicas=3

# before executing the test, we need to include the dns domains in the coredns, so the tests can resolve them
#after 'health'
# edit coredns configmap in kube-system namespace
# rewrite name workspace-1-domain-1.com istio-ingressgateway.istio-gateways.svc.cluster.local
# rewrite name workspace-1-domain-2.com istio-ingressgateway.istio-gateways.svc.cluster.local
# rewrite name workspace-1-domain-3.com istio-ingressgateway.istio-gateways.svc.cluster.local
# rewrite name workspace-1-domain-4.com istio-ingressgateway.istio-gateways.svc.cluster.local
# rewrite name workspace-2-domain-1.com istio-ingressgateway.istio-gateways.svc.cluster.local
# rewrite name workspace-3-domain-1.com istio-ingressgateway.istio-gateways.svc.cluster.local
# rewrite name workspace-4-domain-1.com istio-ingressgateway.istio-gateways.svc.cluster.local
# rewrite name workspace-5-domain-1.com istio-ingressgateway.istio-gateways.svc.cluster.local
# rewrite name workspace-10-domain-1.com istio-ingressgateway.istio-gateways.svc.cluster.local
# rewrite name workspace-20-domain-1.com istio-ingressgateway.istio-gateways.svc.cluster.local
# rewrite name workspace-30-domain-1.com istio-ingressgateway.istio-gateways.svc.cluster.local
# rewrite name workspace-40-domain-1.com istio-ingressgateway.istio-gateways.svc.cluster.local
# rewrite name workspace-50-domain-1.com istio-ingressgateway.istio-gateways.svc.cluster.local
# rewrite name workspace-60-domain-1.com istio-ingressgateway.istio-gateways.svc.cluster.local
# rewrite name workspace-70-domain-1.com istio-ingressgateway.istio-gateways.svc.cluster.local
# rewrite name workspace-80-domain-1.com istio-ingressgateway.istio-gateways.svc.cluster.local
# rewrite name workspace-90-domain-1.com istio-ingressgateway.istio-gateways.svc.cluster.local
# rewrite name workspace-100-domain-1.com istio-ingressgateway.istio-gateways.svc.cluster.local
# and then restart coredns deployment

# Edit Loki daemonset to add the toleration for the taints (TODO: patch)
        # - operator: Exists
        #   effect: NoSchedule