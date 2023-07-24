# environment variables
#export MGMT=eks-lab1
#export CLUSTER1=eks-lab1

# Create test scenarios
pushd ../scenarios
for i in 3 5 10; do
  for j in 10 50 100; do
    for k in 10 50 100; do
      bash gw-domains.sh ${i} ${j} ${k}
      mv cluster1 cluster1-${i}w-${j}d-${k}p
      mv mgmt mgmt-${i}w-${j}d-${k}p
    done
  done
done
popd

# Persistent volume for prometheus
kubectl --context ${MGMT} apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-server
  namespace: gloo-mesh
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: gp2
  resources:
    requests:
      storage: "20Gi"
EOF

# Download dashboards
pushd dashboards
curl https://raw.githubusercontent.com/istio/istio/master/manifests/addons/dashboards/pilot-dashboard.json > pilot-dashboard.json
curl https://raw.githubusercontent.com/istio/istio/master/manifests/addons/dashboards/istio-workload-dashboard.json > istio-workload-dashboard.json
curl https://raw.githubusercontent.com/istio/istio/master/manifests/addons/dashboards/istio-service-dashboard.json > istio-service-dashboard.json
curl https://raw.githubusercontent.com/istio/istio/master/manifests/addons/dashboards/istio-mesh-dashboard.json > istio-mesh-dashboard.json
curl https://raw.githubusercontent.com/istio/istio/master/manifests/addons/dashboards/istio-performance-dashboard.json > istio-performance-dashboard.json
curl https://docs.solo.io/gloo-mesh-enterprise/latest/static/content/observability/gloo-platform-dashboard.json > gloo-platform-dashboard.json
popd

# Spin up environment
aws eks update-nodegroup-config --cluster-name jesus-eks-eks-batch1-1 --nodegroup-name n8-32-t3-2x --scaling-config minSize=0,maxSize=6,desiredSize=6 >/dev/null
aws eks update-nodegroup-config --cluster-name jesus-eks-eks-batch1-1 --nodegroup-name n2-4-t3-medium --scaling-config minSize=0,maxSize=6,desiredSize=6 >/dev/null
aws eks update-nodegroup-config --cluster-name jesus-eks-eks-batch1-1 --nodegroup-name n16-32-c5-4x --scaling-config minSize=0,maxSize=1,desiredSize=1 >/dev/null

# Spin down environment
# aws eks update-nodegroup-config --cluster-name jesus-eks-eks-batch1-1 --nodegroup-name n8-32-t3-2x --scaling-config minSize=0,maxSize=6,desiredSize=0 >/dev/null
# aws eks update-nodegroup-config --cluster-name jesus-eks-eks-batch1-1 --nodegroup-name n2-4-t3-medium --scaling-config minSize=0,maxSize=6,desiredSize=0 >/dev/null
# aws eks update-nodegroup-config --cluster-name jesus-eks-eks-batch1-1 --nodegroup-name n16-32-c5-4x --scaling-config minSize=0,maxSize=1,desiredSize=0 >/dev/null
