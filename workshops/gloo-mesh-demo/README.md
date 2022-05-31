# Gloo Mesh Demo

## Environemnt Variables

```sh
export GLOO_MESH_LICENSE_KEY=<licence_key>

export MGMT=mgmt
export CLUSTER1=cluster1
export CLUSTER2=cluster2
export GLOO_MESH_VERSION=v2.0.5
export ISTIO_VERSION=1.13.4
export ISTIO_IMAGE_REPO=<please ask for repo information>
export ISTIO_IMAGE_TAG=1.13.4-solo
export ENDPOINT_HTTPS_GW_CLUSTER1=localhost:8443
export ENDPOINT_HTTPS_GW_CLUSTER1_EXT=localhost:8443
```

## Infrastructure Setup

* Using [k3d](https://k3d.io/)

```sh
./infra/k3d/setup.sh
```

## Ports

* http://localhost:8091 - Gloo Mesh Dashboard
* http://localhost:9000 - Keycloak cluster1
* http://localhost:8080 - cluster1 Istio ingress gateway port 80
* https://localhost:8443 - cluster1 Istio ingress gateway port 443

## Setup Workshop

```sh
./install/setup.sh
```

## Lab 1 - Install Gloo Mesh

* Skip

```sh
./tracks/01-install-gloo-mesh/skip.sh
```

## Lab 2 - Workspaces

* Setup

```sh
./tracks/02-workspaces/setup.sh
```

* Skip

```sh
./tracks/02-workspaces/skip.sh
```

## Lab 3 - Security

* Setup

```sh
./tracks/03-security/setup.sh
```

## Lab 4 - Multi Cluster Routing

* Setup

```sh
./tracks/04-multi-cluster-routing/skip.sh
```

## Lab 5 - Failover

* Setup

```sh
./tracks/05-failover/setup.sh
```

* Skip

```sh
./tracks/05-failover/skip.sh
```

## Lab 6 - API Gateway

* Setup

```sh
./tracks/06-api-gateway/setup.sh
```



```
./install/setup.sh
./tracks/01-install-gloo-mesh/skip.sh
./tracks/02-workspaces/setup.sh
./tracks/02-workspaces/skip.sh
./tracks/03-security/setup.sh
./tracks/03-security/skip.sh
./tracks/04-multi-cluster-routing/skip.sh
./tracks/05-failover/setup.sh
./tracks/05-failover/skip.sh
./tracks/06-api-gateway/setup.sh
```