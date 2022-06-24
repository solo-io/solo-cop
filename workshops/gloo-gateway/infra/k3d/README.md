## Deploy Kubernetes locally using [k3d](https://k3d.io/)

k3d is a lightweight wrapper to run k3s (Rancher Lab’s minimal Kubernetes distribution) in docker.

k3d makes it very easy to create single- and multi-node k3s clusters in docker, e.g. for local development on Kubernetes.


* Download the `k3d` CLI (here)[https://k3d.io/v5.4.3/#installation]


1. Create a shared docker network so the clusters can communicate with each other.

```sh
docker network create gloo-mesh-network
```

2. Deploy the three kubernetes clusters

```sh
k3d cluster create --wait -c infra/k3d/cluster1.yaml
```

3. Rename the contexts to match the workshop

```sh
kubectl config rename-context k3d-cluster1 cluster1
```


## Teardown

```
k3d cluster delete cluster1
```

## Ports

K3d has been configured to expose these ports for your labs

* http://localhost:8080 - cluster1 Istio ingress gateway port 80
* https://localhost:8443 - cluster1 Istio ingress gateway port 443
* http://localhost:9000 - Keycloak cluster1 (used for external auth)
