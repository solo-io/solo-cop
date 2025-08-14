#!/bin/bash
for TELEMETRY_COLLECTOR_POD in $(kubectl -n gloo-mesh get pod --no-headers \
    -l app.kubernetes.io/name=telemetryCollector | awk {' print $1 '})
do
    echo; echo;
    echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    echo "[DEBUG] Getting logs, getting metrics from pod: ${TELEMETRY_COLLECTOR_POD}, port: 8888,  endpoint: /metrics"
    echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    echo "[INFO] sleeping for 10 seconds. waiting for port forward to start in the background"
    kubectl -n gloo-mesh port-forward pod/"${TELEMETRY_COLLECTOR_POD}" 8888 & PID=$!
    sleep 10
    curl -s http://localhost:8888/metrics > "metrics-from-${TELEMETRY_COLLECTOR_POD}.txt"
    kill $PID
    kubectl -n gloo-mesh logs "${TELEMETRY_COLLECTOR_POD}" -c telemetrycollector > "logs-${TELEMETRY_COLLECTOR_POD}.log"
done