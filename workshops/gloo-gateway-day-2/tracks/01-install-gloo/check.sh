#!/bin/bash

set -e

kubectl get deployment gloo-mesh-mgmt-server -n gloo-mesh || fail-message "Could not find the gloo-mesh-mgmt-server in the gloo-mesh namespace, was Gloo platform installed?"

kubectl get deployment gloo-gateway -n gloo-gateway || fail-message "Could not find the gloo-gateway deployment in the gloo-gateway namespace, was Gloo gateway installed?"

kubectl get namespace gloo-gateway-addons || fail-message "Could not find the gloo-gateway-addons namespace, was the Gloo gateway addons installed?"

kubectl get ExtAuthServer ext-auth-server -n dev-team || fail-message "Could not find the ExtAuthServer named ext-auth-server in the dev-team namespace, was Gloo gateway addons installed?"
