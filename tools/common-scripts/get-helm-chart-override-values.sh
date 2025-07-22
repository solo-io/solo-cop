#!/bin/bash
echo; echo;
echo "#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
echo "Getting helm release names from the gloo-mesh namespace"
echo "#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
GM_MGMT_SERVER_HELM_RELEASE_NAME=$(helm -n gloo-mesh --kube-context $MGMT_CONTEXT ls | grep "gloo-mesh-enterprise" | cut -f1)
GM_AGENT_HELM_RELEASE_NAME_CLUSTER1=$(helm -n gloo-mesh --kube-context $REMOTE_CONTEXT1 ls | grep "gloo-mesh-agent" | cut -f1)
GM_AGENT_HELM_RELEASE_NAME_CLUSTER2=$(helm -n gloo-mesh --kube-context $REMOTE_CONTEXT2 ls | grep "gloo-mesh-agent" | cut -f1)

echo "[DEBUG] Helm release name of mgmt server: ${GM_MGMT_SERVER_HELM_RELEASE_NAME}"
echo "[DEBUG] Helm release name of agent cluster1: ${GM_AGENT_HELM_RELEASE_NAME_CLUSTER1}"
echo "[DEBUG] Helm release name of agent cluster2: ${GM_AGENT_HELM_RELEASE_NAME_CLUSTER2}"

echo; echo;
echo "#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
echo "Get helm chart values"
echo "#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
echo; echo "[INFO] Get existing helm override values for mgmt server"
helm -n gloo-mesh get values "${GM_MGMT_SERVER_HELM_RELEASE_NAME}" \
    --kube-context ${MGMT_CONTEXT} > "${HOME}/values-mgmt-plane-env-backup.yaml";
ls -lh "${HOME}/values-mgmt-plane-env-backup.yaml";
echo;

echo; echo "[INFO] Get existing helm override values for the agent in cluster 1 to reuse in the helm upgrade"
helm -n gloo-mesh get values "${GM_AGENT_HELM_RELEASE_NAME_CLUSTER1}" \
    --kube-context $REMOTE_CONTEXT1 > "${HOME}/values-data-plane-env-${REMOTE_CONTEXT1}-backup.yaml";
ls -lh "${HOME}/values-data-plane-env-${REMOTE_CONTEXT1}-backup.yaml"
echo

echo; echo "[INFO] Cluster 2: Get existing helm override values for the agent to reuse in the helm upgrade"
helm -n gloo-mesh get values "${GM_AGENT_HELM_RELEASE_NAME_CLUSTER2}" \
    --kube-context ${REMOTE_CONTEXT2} > "${HOME}/values-data-plane-env-${REMOTE_CONTEXT2}-backup.yaml";
ls -lh "${HOME}/values-data-plane-env-${REMOTE_CONTEXT2}-backup.yaml"
echo
