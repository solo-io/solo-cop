#!/bin/sh
##
# Usage: ./get-snapshots.sh
# Purpose:
# Gets snapshot input and output json from management server pod/s
# Saves locally in the form of snapshots-[MGMT-SERVER-POD-NAME].zip
##
set -e

for MGMT_SERVER_POD in $(kubectl -n gloo-mesh get pod --no-headers \
                        -l app=gloo-mesh-mgmt-server | awk {' print $1 '})
do
    echo; echo;
    echo "#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    echo "[INFO] Getting snapshot from ${MGMT_SERVER_POD}"
    echo "#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    kubectl -n gloo-mesh port-forward \
        "pod/${MGMT_SERVER_POD}" 9091 >/dev/null 2>&1 &
    CURRENT_PROCESS_ID=$!

    sleep 3

    curl -s localhost:9091/snapshots/input > "input-${MGMT_SERVER_POD}.json"
    curl -s localhost:9091/snapshots/output > "output-${MGMT_SERVER_POD}.json"

    zip "snapshots-${MGMT_SERVER_POD}.zip" "input-${MGMT_SERVER_POD}.json" \
        "output-${MGMT_SERVER_POD}.json"
    echo; echo "[INFO] Snapshots saved in: ${PWD}/snapshots-${MGMT_SERVER_POD}.zip"

    # cleanup
    rm "input-${MGMT_SERVER_POD}.json" "output-${MGMT_SERVER_POD}.json"
    kill $CURRENT_PROCESS_ID
done
