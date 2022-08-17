# Istio ARM

If you are using an M1 or M2 macbook and doing a local kubernetes deployment use this arm based istiooperator file

* Istio installation compatible with ARM / M1 / M2 macbooks

```sh
kubectl create namespace istio-gateways --context $CLUSTER1
istioctl install --set hub=$ISTIO_IMAGE_REPO --set tag=$ISTIO_IMAGE_TAG  -y --context $CLUSTER1 -f install/istio/istiooperator-arm-cluster1.yaml

kubectl create namespace istio-gateways --context $CLUSTER2
istioctl install --set hub=$ISTIO_IMAGE_REPO --set tag=$ISTIO_IMAGE_TAG  -y --context $CLUSTER2 -f install/istio/istiooperator-arm-cluster2.yaml
```
