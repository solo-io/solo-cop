#!/bin/bash

set -e

kubectl get RouteTable currency -n dev-team || fail-message "Could not find the RouteTable currency in the dev-team namespace."

kubectl get ExternalEndpoint httpbin -n dev-team || fail-message "Could not find the ExternalEndpoint httpbin in the dev-team namespace."

kubectl get ExternalService httpbin -n dev-team || fail-message "Could not find the ExternalService httpbin in the dev-team namespace."

kubectl get RouteTable httpbin -n dev-team || fail-message "Could not find the RouteTable httpbin in the dev-team namespace."
