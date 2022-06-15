# Istio ARM

If you are using an M1 or M2 macbook and doing a local kubernetes deployment use this arm based istiooperator file

* Istio installation compatible with ARM / M1 / M2 macbooks
```sh
curl -0l https://raw.githubusercontent.com/solo-io/solo-cop/workshop/workshops/gloo-mesh-demo/install/istio/istiooperator-arm.yaml > istiooperator.yaml

export CLUSTER_NAME=$CLUSTER1
cat istiooperator-arm.yaml| envsubst | istioctl install --set hub=$ISTIO_IMAGE_REPO --set tag=$ISTIO_IMAGE_TAG  -y --context $CLUSTER_NAME -f -


export CLUSTER_NAME=$CLUSTER2
cat istiooperator-arm.yaml| envsubst | istioctl install --set hub=$ISTIO_IMAGE_REPO --set tag=$ISTIO_IMAGE_TAG  -y --context $CLUSTER_NAME -f -
```
