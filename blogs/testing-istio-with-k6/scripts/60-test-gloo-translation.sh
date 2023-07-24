# environment variables
export MGMT=gke-lab1
export CLUSTER1=gke-lab1
SCENARIO=$1
SCENARIO=${SCENARIO:unknown}

date
echo "Waiting for previous test to be finished"
while test $(kubectl --context ${MGMT} -n k6 get po|grep Running|wc -l) -gt "1"; do printf "." && sleep 1; done

# Apply ../scenarios

date
kubectl --context ${CLUSTER1} -n gloo-mesh scale deploy gloo-mesh-mgmt-server --replicas=0
kubectl --context ${CLUSTER1} -n gloo-mesh scale deploy gloo-mesh-agent --replicas=0
kubectl --context ${CLUSTER1} -n gloo-mesh rollout status deploy gloo-mesh-agent
kubectl --context ${CLUSTER1} -n gloo-mesh rollout status deploy gloo-mesh-mgmt-server
kubectl --context ${MGMT} apply --server-side=true -f ../scenarios/mgmt-${SCENARIO#*-} --force-conflicts=true
kubectl --context ${CLUSTER1} apply --server-side=true -f ../scenarios/${SCENARIO} --force-conflicts=true
kubectl --context ${CLUSTER1} -n gloo-mesh scale deploy gloo-mesh-mgmt-server --replicas=1
kubectl --context ${CLUSTER1} -n gloo-mesh scale deploy gloo-mesh-agent --replicas=1
kubectl --context ${CLUSTER1} -n gloo-mesh rollout status deploy gloo-mesh-agent
kubectl --context ${CLUSTER1} -n gloo-mesh rollout status deploy gloo-mesh-mgmt-server

# k --context ${MGMT} get wafpolicy -A -oyaml|sed 's/waf: .*/waf: "disabled"/'|kubectl --context ${MGMT} apply -f -
# k --context ${MGMT} get ExtAuthPolicy -A -oyaml|sed 's/apikey: .*/apikey: "disabled"/'|kubectl --context ${MGMT} apply -f -

k --context ${MGMT} get wafpolicy -n workspace-1 -oyaml|sed 's/waf: .*/waf: "disabled"/'|kubectl --context ${MGMT} apply -f -
k --context ${MGMT} get wafpolicy -n workspace-3 -oyaml|sed 's/waf: .*/waf: "disabled"/'|kubectl --context ${MGMT} apply -f -
k --context ${MGMT} get ExtAuthPolicy -n workspace-1 -oyaml|sed 's/apikey: .*/apikey: "disabled"/'|kubectl --context ${MGMT} apply -f -
k --context ${MGMT} get ExtAuthPolicy -n workspace-2 -oyaml|sed 's/apikey: .*/apikey: "disabled"/'|kubectl --context ${MGMT} apply -f -

# Scale upstreams to avoid bottleneck during tests

echo "Adding a new domain: workspace-1-domain-${SCENARIO#*-}a.com"
kubectl --context ${CLUSTER1} apply -f -<<EOF
apiVersion: networking.gloo.solo.io/v2
kind: VirtualGateway
metadata:
  name: ${SCENARIO#*-}a
  namespace: istio-gateways
spec:
  workloads:
    - selector:
        labels:
          istio: ingressgateway
        cluster: cluster1
  listeners: 
    - http: {}
      port:
        number: 443
      tls:
        mode: SIMPLE
        secretName: wrk-1-dom-1
      allowedRouteTables:
      - host: workspace-1-domain-${SCENARIO#*-}a.com
---
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: ${SCENARIO#*-}a
  namespace: istio-gateways
spec:
  hosts:
    - workspace-1-domain-${SCENARIO#*-}a.com
  virtualGateways:
    - name: ${SCENARIO#*-}a
      namespace: istio-gateways
      cluster: cluster1
  workloadSelectors: []
  http:
    - name: root
      matchers:
      - uri:
          prefix: /
      delegate:
        routeTables:
          - labels:
              workspace: workspace-1
              domain: workspace-1-domain-${SCENARIO#*-}a.com
---
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: dom-${SCENARIO#*-}a
  namespace: workspace-1
  labels:
    workspace: workspace-1
    domain: workspace-1-domain-${SCENARIO#*-}a.com
    expose: "true"
spec:
  http:
    - name: ${SCENARIO#*-}a
      labels:
        apikey: "true"
        waf: "true"
      matchers:
      - uri:
          exact: /get/1
      forwardTo:
        pathRewrite: /
        destinations:
        - ref:
            name: echoenv
            namespace: workspace-1
          port:
            number: 8000
EOF

date
echo "Waiting for Gloo Platform translation"
SECONDS=0
while ! kubectl --context ${CLUSTER1} -n istio-gateways get virtualservices routetable-${SCENARIO#*-}a-istio-gateways-cluster1-gateways 2>/dev/null 1>&2; do printf "." && sleep 1; done
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed to get Gloo Platform translation"
date
echo "Waiting 300s, just in case..."
sleep 300

echo "Adding a new domain: workspace-1-domain-${SCENARIO#*-}b.com"
kubectl --context ${MGMT} apply -f -<<EOF
apiVersion: networking.gloo.solo.io/v2
kind: VirtualGateway
metadata:
  name: ${SCENARIO#*-}b
  namespace: istio-gateways
spec:
  workloads:
    - selector:
        labels:
          istio: ingressgateway
        cluster: cluster1
  listeners: 
    - http: {}
      port:
        number: 443
      tls:
        mode: SIMPLE
        secretName: wrk-1-dom-1
      allowedRouteTables:
      - host: workspace-1-domain-${SCENARIO#*-}b.com
---
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: ${SCENARIO#*-}b
  namespace: istio-gateways
spec:
  hosts:
    - workspace-1-domain-${SCENARIO#*-}b.com
  virtualGateways:
    - name: ${SCENARIO#*-}b
      namespace: istio-gateways
      cluster: cluster1
  workloadSelectors: []
  http:
    - name: root
      matchers:
      - uri:
          prefix: /
      delegate:
        routeTables:
          - labels:
              workspace: workspace-1
              domain: workspace-1-domain-${SCENARIO#*-}b.com
---
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: dom-${SCENARIO#*-}b
  namespace: workspace-1
  labels:
    workspace: workspace-1
    domain: workspace-1-domain-${SCENARIO#*-}b.com
    expose: "true"
spec:
  http:
    - name: ${SCENARIO#*-}b
      labels:
        apikey: "true"
        waf: "true"
      matchers:
      - uri:
          exact: /get/1
      forwardTo:
        pathRewrite: /
        destinations:
        - ref:
            name: echoenv
            namespace: workspace-1
          port:
            number: 8000
EOF

echo "Waiting for Gloo Platform translation of the new domain"
SECONDS=0
while ! kubectl --context ${CLUSTER1} -n istio-gateways get virtualservices routetable-${SCENARIO#*-}b-istio-gateways-cluster1-gateways 2>/dev/null 1>&2; do printf "." && sleep 1; done
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed to get Gloo Platform translation of the new domain"
date

echo "Waiting for Istio IngressGateway to be configured"
IG_IP=$(kubectl --context ${CLUSTER1} get svc -n istio-gateways istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].*}')
IG_IP=$(dig +short ${IG_IP} @8.8.8.8|tail -n1)
APIKEY=N2YwMDIxZTEtNGUzNS1jNzgzLTRkYjAtYjE2YzRkZGVmNjcy
SECONDS=0
while ! curl --silent --fail -k --output /dev/null https://workspace-1-domain-${SCENARIO#*-}b.com/get/1 -H "api-key: ${APIKEY}" --resolve workspace-1-domain-${SCENARIO#*-}b.com:443:${IG_IP}; do printf "." && sleep 1; done
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed to get Istio IngressGateway configured"
date

kubectl --context ${MGMT} -n k6 create job --from=cronjob/k6-load ${SCENARIO#*-}

## Manual test: 5w-100d-100p = 50k routes
# IG_IP=$(kubectl --context ${CLUSTER1} get svc -n istio-gateways istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].*}')
# IG_IP=$(dig +short ${IG_IP} @8.8.8.8|tail -n1)
# echo $IG_IP
# APIKEY=N2YwMDIxZTEtNGUzNS1jNzgzLTRkYjAtYjE2YzRkZGVmNjcy
# curl https://workspace-1-domain-10w-10d-10pb.com/get/1 -H "api-key: ${APIKEY}" --resolve workspace-1-domain-10w-10d-10pb.com:443:${IG_IP} -ksi
# curl https://workspace-1-domain-10w-1000d-100pb.com/get/1 -H "api-key: ${APIKEY}" --resolve workspace-1-domain-10w-1000d-100pb.com:443:${IG_IP} -ksi
# curl https://workspace-4-domain-4.com/get/1 -H "api-key: ${APIKEY}" --resolve workspace-4-domain-4.com:443:${IG_IP} -ksi
# k -n sleep exec deploy/sleep -- curl -H "api-key: ${APIKEY}"  https://workspace-1-domain-1.com/get/100 -ksi
# kubectl -n k6 create job --from=cronjob/k6-load load-manual-domain1
# k get vs -n istio-gateways -oname|grep -v -e wrk-1- -e wrk-10- -e wrk-20- -e wrk-30- -e wrk-40- | xargs kubectl -n istio-gateways delete