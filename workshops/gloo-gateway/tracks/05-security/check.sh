#!/bin/bash

set -e

kubectl get WAFPolicy log4jshell -n dev-team || fail-message "Could not find the WAFPolicy log4jshell in the dev-team namespace."

kubectl get RateLimitPolicy rate-limit-policy -n dev-team || fail-message "Could not find the RateLimitPolicy rate-limit-policy in the dev-team namespace."