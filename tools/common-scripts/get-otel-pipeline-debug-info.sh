# In workload cluster/s
for TELEMETRY_COLLECTOR_POD in $(kubectl -n gloo-mesh get pod --no-headers \
                        -l app.kubernetes.io/name=telemetryCollector | awk {' print $1 '})
do
    echo; echo;
    echo "#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    echo "[INFO] Getting metrics from ${TELEMETRY_COLLECTOR_POD}"
    echo "#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    kubectl -n gloo-mesh port-forward $TELEMETRY_COLLECTOR_POD 8888 & PID=$!
    # depending on how much time it takes to port-forward, the sleep time would be diff in diff environment
    sleep 3
    curl -s http://localhost:8888/metrics > "metrics-from-${TELEMETRY_COLLECTOR_POD}.txt"
    kill $PID
    kubectl -n gloo-mesh logs "${TELEMETRY_COLLECTOR_POD}" > "logs-$TELEMETRY_COLLECTOR_POD.log"
done
kubectl -n gloo-mesh get configmap gloo-telemetry-collector-config -o yaml > gloo-telemetry-collector-config.yaml

# In management clusters
for TELEMETRY_GATEWAY_POD in $(kubectl -n gloo-mesh get pod --no-headers \
                        -l app.kubernetes.io/name=telemetryGateway | awk {' print $1 '})
do
    echo; echo;
    echo "#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    echo "[INFO] Getting metrics from ${TELEMETRY_GATEWAY_POD}"
    echo "#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    kubectl -n gloo-mesh port-forward $TELEMETRY_GATEWAY_POD 9091 & PID=$!
    # depending on how much time it takes to port-forward, the sleep time would be diff in diff environment
    sleep 3
    curl -s http://localhost:9091/metrics > "metrics-from-${TELEMETRY_GATEWAY_POD}.txt"
    kill $PID
    kubectl -n gloo-mesh logs $TELEMETRY_GATEWAY_POD > "logs-${TELEMETRY_GATEWAY_POD}.log"
done
kubectl -n gloo-mesh get configmap gloo-telemetry-gateway-config -o yaml > gloo-telemetry-gateway-config.yaml

grep -Re "^otelcol_receiver_accepted_metric_points" .
echo "####################################################################"
grep -Re "^otelcol_receiver_refused_metric_points" .
echo "####################################################################"
grep -Re "^otelcol_exporter_sent_metric_points" .
echo "####################################################################"
grep -Re "^otelcol_exporter_send_failed_metric_points" .
echo "####################################################################"
grep -Re "^istio_.*" .
echo "####################################################################"
