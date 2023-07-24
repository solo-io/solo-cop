SCENARIO=$1
NGATEWAYS=$2
NVIRTUALSERVICES=$3
NENVOYFILTERS=$4

kubectl --context ${MGMT} apply -f ../scenarios/mgmt-${SCENARIO} --server-side=true --force-conflicts=true --wait=false
kubectl --context ${CLUSTER1} apply -f ../scenarios/cluster1-${SCENARIO} --server-side=true --force-conflicts=true --wait=false

SECONDS=0
# wait until the translation is done
date
echo "Waiting for istio gateways to be created"
while test $(kubectl --context ${MGMT} -n istio-gateways get gateways -oname |wc -l) -lt "${NGATEWAYS}"; do printf "." && sleep 1; done

date
echo "Waiting for istio vs to be created"
while test $(kubectl --context ${MGMT} -n istio-gateways get vs -oname |wc -l) -lt "${NVIRTUALSERVICES}"; do printf "." && sleep 1; done

date
echo "Waiting for istio envoyfilters to be created"
while test $(kubectl --context ${MGMT} -n istio-gateways get envoyfilter -oname |wc -l) -lt "${NENVOYFILTERS}"; do printf "." && sleep 1; done
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed to get all Istio resources"

# make sure that istio ingress gateways is healthy
# k -n sleep exec deploy/sleep -- curl https://workspace-1-domain-1.com/get/100 -ksi

sleep 60

# Create an additional domain
date
echo "Adding a new domain: workspace-1-domain-extra.com"
kubectl --context ${MGMT} apply -f -<<EOF
apiVersion: networking.gloo.solo.io/v2
kind: VirtualGateway
metadata:
  name: wrk-1-extra-domain
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
      - host: workspace-1-domain-extra.com
---
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: wrk-1-extra-domain
  namespace: istio-gateways
spec:
  hosts:
    - workspace-1-domain-extra.com
  virtualGateways:
    - name: wrk-1-extra-domain
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
              domain: workspace-1-domain-extra.com
---
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: dom-extra
  namespace: workspace-1
  labels:
    workspace: workspace-1
    domain: workspace-1-domain-extra.com
    expose: "true"
spec:
  http:
    - name: extra
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

SECONDS=0
# wait until the translation is done
date
echo "Waiting for istio gateways to be created"
while test $(kubectl --context ${MGMT} -n istio-gateways get gateways -oname |wc -l) -lt "$(($NGATEWAYS + 1 ))"; do printf "." && sleep 1; done

date
echo "Waiting for istio vs to be created"
while test $(kubectl --context ${MGMT} -n istio-gateways get vs -oname |wc -l) -lt "$(($NVIRTUALSERVICES + 1 ))"; do printf "." && sleep 1; done

date
echo "Waiting for istio envoyfilters to be created"
while test $(kubectl --context ${MGMT} -n istio-gateways get envoyfilter -oname |wc -l) -lt "$(($NENVOYFILTERS + 1 ))"; do printf "." && sleep 1; done
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed to get all Istio resources"
date

kubectl --context ${MGMT} delete VirtualGateway wrk-1-extra-domain -n istio-gateways
kubectl --context ${MGMT} delete RouteTable wrk-1-extra-domain -n istio-gateways
kubectl --context ${MGMT} delete RouteTable dom-extra -n workspace-1

