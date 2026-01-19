#!/bin/bash
#
# Usage: ./get-gateway-conigs.sh
#
# Description:
#   Collects all Gateway API and KGateway/AgentGateway related custom resources from the
#   Kubernetes cluster and outputs them to a timestamped YAML file.
#
# Prerequisites:
#   - kubectl must be installed and configured with access to the target cluster
#   - User must have permissions to list CRDs and read custom resources across all namespaces
#
# Output:
#   Creates a file named: all-gateway-related-custom-resources-YYYYMMDDHHMMSS.yaml
#   containing all discovered resources from:
#   - gateway.networking.k8s.io API group (standard Gateway API resources)
#   - solo.io, kgateway, and agentgateway related CRDs
#
# Exit codes:
#   0 - Success (resources found and written to file)
#   0 - Success (no resources found, informational message displayed)
#

set -e

timestamp=$(date +%Y%m%d%H%M%S)
found_resources=false

for gateway_api_custom_resource_type in $(kubectl api-resources --api-group=gateway.networking.k8s.io --no-headers | awk '{print $1}'); do
    output=$(kubectl get "${gateway_api_custom_resource_type}" -A -o yaml 2>/dev/null)
    if echo "$output" | grep -q "^- "; then
        echo "---" >> "all-gateway-related-custom-resources-${timestamp}.yaml"
        echo "$output" >> "all-gateway-related-custom-resources-${timestamp}.yaml"
        found_resources=true
    fi
done

for solo_ent_gateway_custom_resource_type in $(kubectl get crds | grep -E "solo.io|kgateway|agentgateway" | awk '{ print $1 }' | cut -d. -f1); do
    output=$(kubectl get "${solo_ent_gateway_custom_resource_type}" -A -o yaml 2>/dev/null)
    if echo "$output" | grep -q "^- "; then
        echo "---" >> "all-gateway-related-custom-resources-${timestamp}.yaml"
        echo "$output" >> "all-gateway-related-custom-resources-${timestamp}.yaml"
        found_resources=true
    fi
done

if [ "${found_resources}" = false ]; then
    echo "[INFO] No Gateway API and Solo Enteprise for KGateway, AgentGateway related custom resources are present in the cluster."
else
    echo "[INFO] Gateway specific Custom Resources saved in: all-gateway-related-custom-resources-${timestamp}.yaml"
fi
