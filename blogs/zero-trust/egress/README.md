# Zero-trust for Egress 
The content contained here is the supplemental assets for the blog post on Zero-trust for Egress.  This is not considered to be a comprehensive
source of documentation on this topic, but a specific example corresponding to the blog content.

## Pre-requisites
This blog assumes that you have installed Gloo Mesh (version 1.2.7 was used at the time of writing) with the typical 3-cluster setup (mgmt, cluster1, cluster2).  Each of the remote clusters should have Istio installed (version 1.10.4 was used). Each of the remote clusters should be registered with the management plane.  See Gloo Mesh [documentation](https://docs.solo.io/gloo-mesh-enterprise/latest/setup/enterprise_cluster_registration/) for details.

## Steps

### Install Istio in remote clusters
There are two example IstioOperator definitions found here.  Both `iop-cluster1.yaml` and `iop-cluster2.yaml` are for the initial test that does not block the Log4Shell vulnerability.  After you have verified the logs for petclinic and istio-proxy, you should use `iop-cluster1-block-egress.yaml` and `iop-cluster2-block-egress.yaml` to turn on the outboundTrafficPolicy.  

Any of these operators can be installed with `istioctl`.  

### Install Petclinic in remote clusters
In each of the remote clusters, perform the following operations.

```
kubectl label ns default istio-injection=enabled
kubectl apply -f petclinic.yaml
```

Wait for the pods to come up.

```
kubectl get pods

NAME                              READY   STATUS    RESTARTS   AGE
petclinic-0                       2/2     Running   0          17s
petclinic-db-0                    2/2     Running   0          17s
petclinic-vets-6dcb5bc466-g785w   2/2     Running   0          17s
```

When they are ready, deploy the VirtualService and Gateway for petclinic.

```
kubectl apply -f petclinic-gateway.yaml
```

Verify the application is running.

```
kubectl -n istio-system get svc
```

Retrieve the external IP or hostname of *istio-ingressgateway* and visit that address in your browser.  You should see the petclinic application.

### Create VirtualMesh

Apply policies across both remote clusters by applying a VirtualMesh in the management plane.

```
kubectl config use-context ${MGMT}
kubectl -n gloo-mesh apply -f virtual-mesh-0.yaml
```

Apply strict mtls to each remote cluster.

```
kubectl --context cluster1 -f strict-mtls.yaml
kubectl --context cluster2 -f strict-mtls.yaml
```

Refresh the application in the browser to ensure it is still working.

### (Optional) Create a Destination that allows access to a specific JDNI lookup

Apply the following policy to allow access to Forum Systems Online LDAP Test Server.

```
kubectl config use-context ${MGMT}
kubectl -n gloo-mesh apply -f forumsystems-dest.yaml
```

