#!/bin/bash
set -e

timestamp=$(date +%Y%m%d%H%M%S)
found_resources=false

for gateway_api_custom_resource_type in $(kubectl api-resources --api-group=gateway.networking.k8s.io --no-headers | awk '{print $1}'); do
    output=$(kubectl get "${gateway_api_custom_resource_type}" -A -o yaml 2>/dev/null)
    if echo "$output" | grep -q "^- "; then
        echo "---" >> "all-gloo-gateway-related-custom-resources-${timestamp}.yaml"
        echo "$output" >> "all-gloo-gateway-related-custom-resources-${timestamp}.yaml"
        found_resources=true
    fi
done

for gloo_gateway_custom_resource_type in $(kubectl get crds | grep -E "solo.io|kgateway" | awk '{ print $1 }' | cut -d. -f1); do
    output=$(kubectl get "${gloo_gateway_custom_resource_type}" -A -o yaml 2>/dev/null)
    if echo "$output" | grep -q "^- "; then
        echo "---" >> "all-gloo-gateway-related-custom-resources-${timestamp}.yaml"
        echo "$output" >> "all-gloo-gateway-related-custom-resources-${timestamp}.yaml"
        found_resources=true
    fi
done

if [ "${found_resources}" = false ]; then
    echo "No Gateway API and Gloo Gateway API related custom resources are present in the cluster."
else
    echo "Output file: all-gloo-gateway-related-custom-resources-${timestamp}.yaml"
fi