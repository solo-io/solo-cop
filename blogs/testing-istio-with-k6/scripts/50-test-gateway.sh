#kubectl --context ${MGMT} delete gatewaylifecyclemanagers.admin.gloo.solo.io -A --all
#sleep 10

CPU=1000m MEMORY=4Gi bash k6-gw.sh
sleep 120
kubectl --context ${MGMT} -n istio-gateways rollout status deployment istio-ingressgateway-1-18
bash k6.sh

CPU=2000m MEMORY=4Gi bash k6-gw.sh
sleep 120
kubectl --context ${MGMT} -n istio-gateways rollout status deployment istio-ingressgateway-1-18
bash k6.sh

CPU=4000m MEMORY=4Gi bash k6-gw.sh
sleep 120
kubectl --context ${MGMT} -n istio-gateways rollout status deployment istio-ingressgateway-1-18
bash k6.sh

CPU=8000m MEMORY=4Gi bash k6-gw.sh
sleep 120
kubectl --context ${MGMT} -n istio-gateways rollout status deployment istio-ingressgateway-1-18
bash k6.sh

# CPU=10000m MEMORY=4Gi bash k6-gw.sh
# sleep 20
# kubectl --context ${MGMT} -n istio-gateways rollout status deployment istio-ingressgateway-1-18
# bash k6.sh