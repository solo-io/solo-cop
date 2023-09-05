#!/bin/bash
export MGMT_SERVER_POD=$1

SECONDS_FOR_CAPTURING_PROFILE=120

# start port-forward and capture process ID
kubectl -n gloo-mesh port-forward "pod/${MGMT_SERVER_POD}" 9091 >/dev/null 2>&1 &
CURRENT_PROCESS_ID=$!
sleep 10

##
# snapshots
##
echo; echo "[INFO] getting snapshot from management server pod ${MGMT_SERVER_POD} ..."; echo
curl -s localhost:9091/snapshots/input > "input-${MGMT_SERVER_POD}.json"
curl -s localhost:9091/snapshots/output > "output-${MGMT_SERVER_POD}.json"

echo; echo "[INFO] compressing input snapshot..."; echo
tar -zcvf "input-snapshot-${MGMT_SERVER_POD}.tar.gz" "input-${MGMT_SERVER_POD}.json"

echo; echo "[INFO] compressing output snapshot..."; echo
tar -zcvf "output-snapshot-${MGMT_SERVER_POD}.tar.gz" "output-${MGMT_SERVER_POD}.json"

##
# Allocs, heap, profile
##
echo; echo "[INFO] get /allocs from management server pod ${MGMT_SERVER_POD}"; echo
wget localhost:9091/debug/pprof/allocs -O "allocs-${MGMT_SERVER_POD}"

echo; echo "[INFO] get /heap from management server pod ${MGMT_SERVER_POD} ..."; echo
wget localhost:9091/debug/pprof/heap -O "heap-${MGMT_SERVER_POD}"

echo; echo "[INFO] get /profile from management server pod ${MGMT_SERVER_POD} for ${SECONDS_FOR_CAPTURING_PROFILE} seconds..."; echo
wget "localhost:9091/debug/pprof/profile?seconds=${SECONDS_FOR_CAPTURING_PROFILE}" -O "profile-${SECONDS_FOR_CAPTURING_PROFILE}-sec-${MGMT_SERVER_POD}"

##
# Print file absolute paths
## 
echo
echo "[INFO] Input Snapshot saved in: ${PWD}/input-snapshot-${MGMT_SERVER_POD}.tar.gz"
echo "[INFO] Output Snapshot saved in: ${PWD}/output-snapshot-${MGMT_SERVER_POD}.tar.gz"
echo "[INFO] /allocs saved in: ${PWD}/allocs-${MGMT_SERVER_POD}"
echo "[INFO] /heap saved in: ${PWD}/heap-${MGMT_SERVER_POD}"
echo "[INFO] /profile?seconds=${SECONDS_FOR_CAPTURING_PROFILE} saved in: ${PWD}/profile-${SECONDS_FOR_CAPTURING_PROFILE}-sec-${MGMT_SERVER_POD}"
echo

# compressing all the files in one:
tar -zcvf "all-files-compressed-${MGMT_SERVER_POD}.tar.gz" \
    "input-snapshot-${MGMT_SERVER_POD}.tar.gz" \
    "output-snapshot-${MGMT_SERVER_POD}.tar.gz" \
    "allocs-${MGMT_SERVER_POD}" \
    "heap-${MGMT_SERVER_POD}" \
    "profile-${SECONDS_FOR_CAPTURING_PROFILE}-sec-${MGMT_SERVER_POD}"

# stop port-forward
kill $CURRENT_PROCESS_ID