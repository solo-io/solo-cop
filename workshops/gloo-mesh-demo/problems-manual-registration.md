# Cluster registration without automatic endpoint discovery

Get the Gloo Mesh Management Server endpoint:
```sh
export GLOO_MESH_ENDPOINT=$(kubectl --context ${MGMT} -n gloo-mesh get svc gloo-mesh-mgmt-server -o jsonpath='{.status.loadBalancer.ingress[0].*}'):9900

echo "Gloo Mesh Endpoint: $GLOO_MESH_ENDPOINT"
```

* Register the clusters with the endpoint

```sh
meshctl cluster register \
  --kubecontext=$MGMT \
  --remote-context=$CLUSTER1 \
  --relay-server-address $GLOO_MESH_ENDPOINT \
  $CLUSTER1

meshctl cluster register \
  --kubecontext=$MGMT \
  --remote-context=$CLUSTER2 \
  --relay-server-address $GLOO_MESH_ENDPOINT \
  $CLUSTER2
```
