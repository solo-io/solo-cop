#!/bin/bash

set -e

kubectl get Secret solo-admin -n dev-team || fail-message "Could not find the Secret solo-admin in the dev-team namespace."

kubectl get Secret solo-developer -n dev-team || fail-message "Could not find the Secret solo-developer in the dev-team namespace."

kubectl get ExtAuthPolicy httpbin-apikey -n dev-team || fail-message "Could not find the ExtAuthPolicy httpbin-apikey in the dev-team namespace."

kubectl get ExternalEndpoint auth0 -n dev-team || fail-message "Could not find the ExternalEndpoint auth0 in the dev-team namespace."

kubectl get ExternalService auth0 -n dev-team || fail-message "Could not find the ExternalService auth0 in the dev-team namespace."

kubectl get JWTPolicy currency -n dev-team || fail-message "Could not find the JWTPolicy currency in the dev-team namespace."

kubectl get ExtAuthPolicy frontend -n dev-team || fail-message "Could not find the ExtAuthPolicy frontend in the dev-team namespace."
