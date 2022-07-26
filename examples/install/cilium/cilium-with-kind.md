# Using Cilium in KinD

Follow these steps to get a KinD cluster up and running and then proceed to install the cilium CNI and CLI

## Prerequisites
- Ensure you have a recent version of Docker enabled
- Ensure the system you run this on is a recent version of Linux
- Have at least 4 CPU Cores and 8GBs of RAM available

## Steps

### Install KinD
```
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.14.0/kind-linux-amd64
chmod +x ./kind
mv ./kind /[CHANGE-TO-ME-SOME-DIR-IN-YOUR-PATH/kind
```
### Create KinD Cluster

```
cat <<EOF | kubectl apply -f -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: cilium
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
networking:
  disableDefaultCNI: true
EOF
```

### Download Cilium CLI 
```
curl cilium cli download
```

### Install Cilium
```
cilium install
```
### Determine the status of Cilium
```
cilium status
```
### Check Pods for Cilium
```
kubectl get pods -A (to verify coreDNS pods are up and running) 
```

### Deploy the Bookinfo application
```
https://raw.githubusercontent.com/istio/istio/release-1.14/samples/bookinfo/platform/kube/bookinfo.yaml
```

### Check status of pods
```
kubectl get pods -o wide
```

At this point, you should see that all pods are up and running along with the Bookinfo application's pods. All pods will have IPs.

You can proceed to do further testing as necessary.
