# Gloo Mesh Demo

## Environemnt Variables

```sh
export GLOO_MESH_LICENSE_KEY=<licence_key>

export MGMT=mgmt
export CLUSTER1=cluster1
export CLUSTER2=cluster2
export GLOO_MESH_VERSION=v2.0.2
export ISTIO_VERSION=1.12.7
```

## Infrastructure Setup

* Using [k3d](https://k3d.io/)

```sh
./infra/k3d/setup.sh
```

## Ports

* http://localhost:8091 - Gloo Mesh Dashboard
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
./tracks/04-multi-cluster-routing/setup.sh
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