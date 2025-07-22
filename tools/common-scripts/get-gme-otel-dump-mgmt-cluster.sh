#!/bin/bash
START_TIME=$(date +"%Y-%m-%d-%H%M%S")
for TELEMETRY_COLLECTOR_POD in $(kubectl -n gloo-mesh get pod --no-headers \
                        -l app.kubernetes.io/name=telemetryCollector | awk {' print $1 '})
do
    echo "#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    echo "[DEBUG] Getting metrics from ${TELEMETRY_COLLECTOR_POD}"
    echo "#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    kubectl -n gloo-mesh port-forward "${TELEMETRY_COLLECTOR_POD}" 8888 & PID=$!
    # depending on how much time it takes to port-forward, the sleep time would be diff in diff environment
    sleep 5
    curl -s http://localhost:8888/metrics > "metrics-from-port-8888-${TELEMETRY_COLLECTOR_POD}-${START_TIME}.txt"
    kill $PID

	kubectl -n gloo-mesh port-forward "${TELEMETRY_COLLECTOR_POD}" 9091 & PID=$!
    # depending on how much time it takes to port-forward, the sleep time would be diff in diff environment
    sleep 5
    curl -s http://localhost:9091/metrics > "metrics-from-port-9091-${TELEMETRY_COLLECTOR_POD}-${START_TIME}.txt"
    kill $PID
	
    kubectl -n gloo-mesh logs "${TELEMETRY_COLLECTOR_POD}" > "logs-${TELEMETRY_COLLECTOR_POD}-${START_TIME}.log"
done
kubectl -n gloo-mesh get configmap gloo-telemetry-collector-config -o yaml > "gloo-telemetry-collector-config-${START_TIME}.yaml"

# In management clusters
for TELEMETRY_GATEWAY_POD in $(kubectl -n gloo-mesh get pod --no-headers \
                        -l app.kubernetes.io/name=telemetryGateway | awk {' print $1 '})
do
    echo; echo;
    echo "#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    echo "[DEBUG] Getting metrics from ${TELEMETRY_GATEWAY_POD}"
    echo "#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    kubectl -n gloo-mesh port-forward "${TELEMETRY_GATEWAY_POD}" 9091 & PID=$!
    # depending on how much time it takes to port-forward, the sleep time would be diff in diff environment
    sleep 5
    curl -s http://localhost:9091/metrics > "metrics-from-port-9091-${TELEMETRY_GATEWAY_POD}-${START_TIME}.txt"
    kill $PID

    kubectl -n gloo-mesh port-forward "${TELEMETRY_GATEWAY_POD}" 8888 & PID=$!
    # depending on how much time it takes to port-forward, the sleep time would be diff in diff environment
    sleep 5
    curl -s http://localhost:8888/metrics > "metrics-from-port-8888-${TELEMETRY_GATEWAY_POD}-${START_TIME}.txt"
    kill $PID
    kubectl -n gloo-mesh logs "${TELEMETRY_GATEWAY_POD}" > "logs-${TELEMETRY_GATEWAY_POD}-${START_TIME}.log"
done
kubectl -n gloo-mesh get configmap gloo-telemetry-gateway-config -o yaml > "gloo-telemetry-gateway-config-${START_TIME}.yaml"

tar -zcvf "otel-gateway-and-otel-collector-dump-${START_TIME}.tar.gz" ./*"-${START_TIME}"*

echo; echo; echo "#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
echo "[DEBUG] All files compressed and saved in: otel-gateway-and-otel-collector-dump-${START_TIME}.tar.gz"
echo "#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

rm ./*"-${START_TIME}".yaml ./*"-${START_TIME}".log ./*"-${START_TIME}".txt
