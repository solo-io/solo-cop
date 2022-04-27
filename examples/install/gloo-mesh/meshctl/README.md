# Install Gloo Mesh Using meshctl

![3 Cluster Install](./3-cluster-setup.png)

This example installation is for a typical 3 cluster setup using meshctl which can be downloaded shown below


## Environment Variables
```
export MGMT_CONTEXT=mgmt
export REMOTE_CONTEXT1=cluster1
export REMOTE_CONTEXT2=cluster2

export GLOO_MESH_VERSION=v2.0.0-beta32
```


## Install meshctl

```sh
curl -sL https://run.solo.io/meshctl/install | GLOO_MESH_VERSION=${GLOO_MESH_VERSION} sh -
```

## Install management plane
```sh
meshctl install \
  --kubecontext $MGMT_CONTEXT \
  --license $GLOO_MESH_LICENSE_KEY \
  --version $GLOO_MESH_VERSION \
  --set mgmtClusterName=$MGMT_CLUSTER
```

## Install control planes
```sh
meshctl cluster register \
  --kubecontext=$MGMT_CONTEXT \
  --remote-context=$REMOTE_CONTEXT1 \
  --version $GLOO_MESH_VERSION \
  $REMOTE_CLUSTER1

meshctl cluster register \
  --kubecontext=$MGMT_CONTEXT \
  --remote-context=$REMOTE_CONTEXT2 \
  --version $GLOO_MESH_VERSION \
  $REMOTE_CLUSTER2
```