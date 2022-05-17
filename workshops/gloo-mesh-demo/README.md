# Gloo Mesh Demo

## Environemnt Variables

```sh
export GLOO_MESH_LICENSE_KEY=<licence_key>

export MGMT=mgmt
export CLUSTER1=cluster1
export CLUSTER2=cluster2
export GLOO_MESH_VERSION=v2.0.0
export ISTIO_VERSION=1.12.7
```

## Infrastructure Setup

* Using [k3d](https://k3d.io/)

```sh
./infra/k3d/setup.sh
```


## Ports

* localhost:8091 - Gloo Mesh Dashboard
* localhost:8080 - cluster1 Istio ingress gateway port 80
* localhost:8443 - cluster1 Istio ingress gateway port 443

