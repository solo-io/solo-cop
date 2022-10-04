Let's get istio up and online with Otel

Prereqs:
- helm installed to deploy Istio (local)
- kubectl (local)
- a recent K8s clusters of your choice, deployed 
- Otel collector (deployed with helm)

# setup

kubectl create ns otel

helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts

helm install opentelemetry-collector open-telemetry/opentelemetry-collector -f otel.values.yaml -n otel --createnamespace --debug

## Istio

```console
helmfile --debug sync
```
## Bookinfo

kubectl label namespace default istio-injection=enabled
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.15/samples/bookinfo/platform/kube/bookinfo.yaml

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.15/samples/bookinfo/networking/bookinfo-gateway.yaml


kubectl get svc istio-ingressgateway -n istio-system
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')


export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

curl -s "http://${GATEWAY_URL}/productpage" | grep -o "<title>.*</title>"

for i in $(seq 1 100); do curl -s -o /dev/null "http://$GATEWAY_URL/productpage"; done

