#!/bin/bash
for TELEMETRY_GATEWAY_POD in $(kubectl -n gloo-mesh get pod --no-headers \
	-l app.kubernetes.io/name=telemetryGateway | awk {' print $1 '})
do
    echo; echo;
    echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    echo "[DEBUG] Getting logs, getting metrics from pod: ${TELEMETRY_GATEWAY_POD}, port: 9091,  endpoint: /metrics"
    echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    echo "[INFO] sleeping for 10 seconds. waiting for port forward to start in the background"
    kubectl -n gloo-mesh port-forward pod/"${TELEMETRY_GATEWAY_POD}" 9091 & PID=$!
    sleep 10
    curl -s http://localhost:9091/metrics > "metrics-from-${TELEMETRY_GATEWAY_POD}.txt"
    kill $PID
    kubectl -n gloo-mesh logs "${TELEMETRY_GATEWAY_POD}" > "logs-${TELEMETRY_GATEWAY_POD}.log"
done