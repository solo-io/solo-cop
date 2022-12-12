# Install Istio using Helm

This installation of Istio is for your typical 3 cluster Gloo Mesh installation. It will cover installing Istio configured to work with Gloo Mesh 2.0


## Istio Helm Chart

* You can find Istios official charts here https://artifacthub.io/packages/search?org=istio

```sh
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
```

## Environment Variables
```sh
ISTIO_VERSION=1.16.0
REMOTE_CLUSTER1=cluster-1
REMOTE_CLUSTER2=cluster-2
```

## Istio Installation

* Namespace and CRD installation

```sh
# Install Istio CRDS cluster1
helm install istio-base istio/base \
  -n istio-system \
  --version $ISTIO_VERSION \
  --kube-context $REMOTE_CLUSTER1 \
  --create-namespace

# Install Istio CRDS cluster2
helm install istio-base istio/base \
  -n istio-system \
  --version $ISTIO_VERSION \
  --kube-context $REMOTE_CLUSTER2\
  --create-namespace
```

* Istiod configuration and installation

```sh
# Install istiod cluster1
helm install istiod istio/istiod \
  -f cluster1-values.yaml \
  --namespace istio-system \
  --version $ISTIO_VERSION \
  --kube-context $REMOTE_CLUSTER1

# Install istiod cluster2
helm install istiod istio/istiod \
  -f cluster2-values.yaml \
  --namespace istio-system \
  --version $ISTIO_VERSION \
  --kube-context $REMOTE_CLUSTER2
```

## Ingress Gateway Install

* Installs the ingress gateways into cluster1 and cluster2

```sh
# Install Istio Ingress Gateway Cluster 1
helm install istio-ingressgateway istio/gateway \
  -f cluster1-ingress-values.yaml \
  --namespace istio-ingress \
  --version $ISTIO_VERSION \
  --kube-context $REMOTE_CLUSTER1 \
  --create-namespace

# Install Istio Ingress Gateway Cluster 2
helm install istio-ingressgateway istio/gateway \
  -f cluster2-ingress-values.yaml \
  --namespace istio-ingress \
  --version $ISTIO_VERSION \
  --kube-context $REMOTE_CLUSTER2 \
  --create-namespace
```

## Eastwest Gateway Install

* Installs the eastwest gateways into cluster1 and cluster2

```sh
# Install Istio Eastwest Gateway Cluster 1
helm install istio-eastwestgateway istio/gateway \
  -f cluster1-eastwest-values.yaml \
  --namespace istio-eastwest \
  --version $ISTIO_VERSION \
  --kube-context $REMOTE_CLUSTER1 \
  --create-namespace

# Install Istio Eastwest Gateway Cluster 2
helm install istio-eastwestgateway istio/gateway \
  -f cluster2-eastwest-values.yaml \
  --namespace istio-eastwest \
  --version $ISTIO_VERSION \
  --kube-context $REMOTE_CLUSTER2 \
  --create-namespace
```
