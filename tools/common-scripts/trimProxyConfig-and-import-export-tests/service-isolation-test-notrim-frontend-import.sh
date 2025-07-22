export MGMT=drew-mgmt
export CLUSTER1=bgottfri-cluster-1
export ISTIO_REV=1-17
export FRONTEND_POD=$(kubectl get pod -n podinfo-frontend --context $CLUSTER1 --no-headers -o custom-columns=":metadata.name")
export BACKEND_POD=$(kubectl get pod -n podinfo-backend --context $CLUSTER1 --no-headers -l "app.kubernetes.io/name=podinfo-backend" -o custom-columns=":metadata.name")



echo "Modifying podinfo-frontend WorkspaceSettings to import from podinfo-backend Workspace"
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
      trimProxyConfig: false
  importFrom:
  - workspaces:
    - name: podinfo-backend 
EOF

echo "Modifying podinfo-backend WorkspaceSettings to export to podinfo-frontend Workspace"
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
      trimProxyConfig: false
  exportTo:
  - workspaces:
    - name: podinfo-frontend
EOF

sleep 10


export FRONTEND_PEERAUTHENTICATION=settings-podinfo-frontend-9898-podinfo-frontend
echo "$FRONTEND_POD peerauthentication:"
kubectl get peerauthentication -n podinfo-frontend settings-podinfo-frontend-9898-podinfo-frontend -o yaml
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