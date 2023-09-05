#!/bin/bash
# Usage:
# ./get-snapshots-and-profiles.sh ${MANAGEMENT_SERVER_POD_NAME}
export MGMT_SERVER_POD=$1

SECONDS_FOR_CAPTURING_PROFILE=120
SLEEP_SECONDS_AS_WE_WAIT_FOR_PORT_FORWARDING_TO_START=10

# start port-forward and capture process ID
kubectl -n gloo-mesh port-forward "pod/${MGMT_SERVER_POD}" 9091 >/dev/null 2>&1 &
CURRENT_PROCESS_ID=$!

##
# Ideally, it should not take more than 10 seconds to do the port forward.
# In some customer env have noticed a lag, thus the 10 sec sleep.
##
echo "[DEBUG] sleeping for ${SLEEP_SECONDS_AS_WE_WAIT_FOR_PORT_FORWARDING_TO_START} seconds to wait for the port forwarding to start in the background..."
sleep $SLEEP_SECONDS_AS_WE_WAIT_FOR_PORT_FORWARDING_TO_START

##
# snapshots
##
echo; echo "[INFO] getting input snapshot from ${MGMT_SERVER_POD} ..."; echo
curl -s localhost:9091/snapshots/input > "input-${MGMT_SERVER_POD}.json"
echo; echo "[INFO] getting output snapshot from ${MGMT_SERVER_POD} ..."; echo
curl -s localhost:9091/snapshots/output > "output-${MGMT_SERVER_POD}.json"

echo; echo "[INFO] compressing input snapshot..."; echo
tar -zcvf "input-snapshot-${MGMT_SERVER_POD}.tar.gz" "input-${MGMT_SERVER_POD}.json"

echo; echo "[INFO] compressing output snapshot..."; echo
tar -zcvf "output-snapshot-${MGMT_SERVER_POD}.tar.gz" "output-${MGMT_SERVER_POD}.json"

##
# Allocs, heap, profile
##
echo; echo "[INFO] get /debug/pprof/allocs from ${MGMT_SERVER_POD}"; echo
wget localhost:9091/debug/pprof/allocs -O "allocs-${MGMT_SERVER_POD}"

echo; echo "[INFO] get /debug/pprof/heap from ${MGMT_SERVER_POD} ..."; echo
wget localhost:9091/debug/pprof/heap -O "heap-${MGMT_SERVER_POD}"

echo; echo "[INFO] get /debug/pprof/profile from ${MGMT_SERVER_POD} for ${SECONDS_FOR_CAPTURING_PROFILE} seconds..."; echo
wget "localhost:9091/debug/pprof/profile?seconds=${SECONDS_FOR_CAPTURING_PROFILE}" -O "profile-${SECONDS_FOR_CAPTURING_PROFILE}-sec-${MGMT_SERVER_POD}"

##
# Print file absolute paths
## 
echo
echo "[DEBUG] Input Snapshot saved in:       ${PWD}/input-snapshot-${MGMT_SERVER_POD}.tar.gz"
echo "[DEBUG] Output Snapshot saved in:      ${PWD}/output-snapshot-${MGMT_SERVER_POD}.tar.gz"
echo "[DEBUG] /allocs saved in:              ${PWD}/allocs-${MGMT_SERVER_POD}"
echo "[DEBUG] /heap saved in:                ${PWD}/heap-${MGMT_SERVER_POD}"
echo "[DEBUG] /profile?seconds=${SECONDS_FOR_CAPTURING_PROFILE} saved in: ${PWD}/profile-${SECONDS_FOR_CAPTURING_PROFILE}-sec-${MGMT_SERVER_POD}"
echo

# compressing all the files in one:
tar -zcvf "all-files-compressed-${MGMT_SERVER_POD}.tar.gz" \
    "input-snapshot-${MGMT_SERVER_POD}.tar.gz" \
    "output-snapshot-${MGMT_SERVER_POD}.tar.gz" \
    "allocs-${MGMT_SERVER_POD}" \
    "heap-${MGMT_SERVER_POD}" \
    "profile-${SECONDS_FOR_CAPTURING_PROFILE}-sec-${MGMT_SERVER_POD}"

echo; echo "[INFO] All files compressed:     ${PWD}/all-files-compressed-${MGMT_SERVER_POD}.tar.gz"

# stop port-forward
kill $CURRENT_PROCESS_ID