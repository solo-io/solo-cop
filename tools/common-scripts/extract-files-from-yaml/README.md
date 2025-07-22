# Usage

## Step 1 - Get the CRs in one yaml

Get all GME CRs
```bash
kubectl get solo-io -A -o yaml > gloo-mesh-crs.yaml
```

## Step 2 - Run the script

Pass the yaml file name as parameter to extract and organize the CRs by folder.

```bash
./extract-files-from-yaml.sh gloo-mesh-crs.yaml
```

## Get other relevant CRs

### Get all Istio CRs
```bash
kubectl get istio-io -A -o yaml > istio-crs.yaml
```

### Get all Gloo Edge/Gateway CRs
```bash
for n in $(kubectl get crds | grep -E 'solo.io|gateway.networking.k8s.io' | awk '{print $1}'); do 
  kubectl get $n --all-namespaces -o yaml >> gloo-gateway-configuration.yaml; 
  echo "---" >> gloo-gateway-configuration.yaml; 
done
```
