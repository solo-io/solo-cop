export MGMT=drew-mgmt
export CLUSTER1=bgottfri-cluster-1
export ISTIO_REV=1-17

kubectl create ns podinfo-frontend --context $MGMT
kubectl create ns podinfo-backend --context $MGMT
kubectl create ns podinfo-frontend --context $CLUSTER1
kubectl label ns podinfo-frontend --context $CLUSTER1 istio.io/rev=$ISTIO_REV
kubectl create ns podinfo-backend --context $CLUSTER1
kubectl label ns podinfo-backend --context $CLUSTER1 istio.io/rev=$ISTIO_REV

echo "Creating podinfo-frontend Workspace"
kubectl apply --context ${MGMT} -f - <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: Workspace
metadata:
  name: podinfo-frontend
  namespace: gloo-mesh
spec:
  workloadClusters:
  - configEnabled: true
    name: drew-mgmt
    namespaces:
    - name: podinfo-frontend
  - configEnabled: true
    name: bgottfri-cluster-1
    namespaces:
    - name: podinfo-frontend
EOF


echo "Creating podinfo-backend Workspace"
kubectl apply --context ${MGMT} -f - <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: Workspace
metadata:
  name: podinfo-backend
  namespace: gloo-mesh
spec:
  workloadClusters:
  - configEnabled: true
    name: drew-mgmt
    namespaces:
    - name: podinfo-backend
  - configEnabled: true
    name: bgottfri-cluster-1
    namespaces:
    - name: podinfo-backend
EOF

echo "Creating podinfo-frontend WorkspaceSettings with no import/export"
kubectl apply --context ${MGMT} -f - <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: WorkspaceSettings
metadata:
  name: podinfo-frontend
  namespace: podinfo-frontend
spec:
  options:
    eastWestGateways:
    - selector:
        labels:
          istio: eastwestgateway
    federation:
      enabled: false
    serviceIsolation:
      enabled: true
      trimProxyConfig: true     
EOF

echo "Creating podinfo-backend WorkspaceSettings with no import/export"
kubectl apply --context ${MGMT} -f - <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: WorkspaceSettings
metadata:
  name: podinfo-backend
  namespace: podinfo-backend
spec:
  options:
    eastWestGateways:
    - selector:
        labels:
          istio: eastwestgateway
    federation:
      enabled: false
    serviceIsolation:
      enabled: true
      trimProxyConfig: true
EOF


echo "Creating podinfo-frontend helm release"
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo update
helm upgrade --install --wait podinfo-frontend \
--namespace podinfo-frontend \
--set replicaCount=1 \
--set backend=http://podinfo-backend.podinfo-backend.svc.cluster.local:9898/echo \
podinfo/podinfo

export FRONTEND_POD=$(kubectl get pod -n podinfo-frontend --context $CLUSTER1 --no-headers -o custom-columns=":metadata.name")
echo "Frontend pod is $FRONTEND_POD"

echo "Creating podinfo-backend helm release"
helm upgrade --install --wait podinfo-backend \
--namespace podinfo-backend \
--set redis.enabled=true \
podinfo/podinfo

export BACKEND_POD=$(kubectl get pod -n podinfo-backend --context $CLUSTER1 --no-headers -l "app.kubernetes.io/name=podinfo-backend" -o custom-columns=":metadata.name")
echo "Backend pod is $BACKEND_POD"

sleep 10

export FRONTEND_PEERAUTHENTICATION=settings-podinfo-frontend-9898-podinfo-frontend
echo "$FRONTEND_POD peerauthentication:"
kubectl get authorizationpolicy -n podinfo-frontend settings-podinfo-frontend-9898-podinfo-frontend -o yaml
echo "\n"

export FRONTEND_AUTHPOLICY=settings-podinfo-frontend-9898-podinfo-frontend
echo "$FRONTEND_POD authorizationpolicy:"
kubectl get authorizationpolicy -n podinfo-frontend settings-podinfo-frontend-9898-podinfo-frontend -o yaml
echo "\n"

echo "$FRONTEND_POD sidecar clusters:"
istioctl pc cluster -n podinfo-frontend $FRONTEND_POD
echo "\n"

export BACKEND_PEERAUTHENTICATION=settings-podinfo-backend-9898-podinfo-backend
echo "$BACKEND_POD peerauthentication:"
kubectl get peerauthentication -n podinfo-backend settings-podinfo-backend-9898-podinfo-backend -o yaml
echo "\n"

export BACKEND_AUTHPOLICY=settings-podinfo-backend-9898-podinfo-backend
echo "$BACKEND_POD authorizationpolicy:"
kubectl get authorizationpolicy -n podinfo-backend settings-podinfo-backend-9898-podinfo-backend -o yaml
echo "\n"

echo "$BACKEND_POD sidecar clusters:"
istioctl pc cluster -n podinfo-backend $BACKEND_POD
echo "\n"