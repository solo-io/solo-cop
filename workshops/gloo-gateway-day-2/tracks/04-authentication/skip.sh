#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# api key secrets

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: solo-admin
  namespace: dev-team
  labels:
    api-keyset: httpbin-users
type: extauth.solo.io/apikey
data:
  api-key: $(echo -n "admin" | base64)
---
apiVersion: v1
kind: Secret
metadata:
  name: solo-developer
  namespace: dev-team
  labels:
    api-keyset: httpbin-users
type: extauth.solo.io/apikey
data:
  api-key: $(echo -n "developer" | base64)
EOF

# Api key ext auth

kubectl apply -f - <<EOF
apiVersion: security.policy.gloo.solo.io/v2
kind: ExtAuthPolicy
metadata:
  name: httpbin-apikey
  namespace: dev-team
spec:
  applyToRoutes:
  - route:
      labels:
        route: httpbin
  config:
    server:
      name: ext-auth-server
      namespace: dev-team
      cluster: mgmt-cluster
    glooAuth:
      configs:
      - apiKeyAuth:
          headerName: x-api-key
          labelSelector:
            api-keyset: httpbin-users
EOF

# Auth0 external service

kubectl apply -f - <<EOF
apiVersion: networking.gloo.solo.io/v2
kind: ExternalEndpoint
metadata:
  name: auth0
  namespace: dev-team
  labels:
    external-service: auth0
spec:
  address: dev-64ktibmv.us.auth0.com
  ports:
    - name: https
      number: 443
---
apiVersion: networking.gloo.solo.io/v2
kind: ExternalService
metadata:
  name: auth0
  namespace: dev-team
spec:
  selector:
    external-service: auth0
  hosts:
  - dev-64ktibmv.us.auth0.com
  ports:
  - name: https
    number: 443
    protocol: HTTPS
    clientsideTls: {}
EOF

# JWT policy

kubectl apply -f - <<EOF
apiVersion: security.policy.gloo.solo.io/v2
kind: JWTPolicy
metadata:
  name: currency
  namespace: dev-team
spec:
  applyToRoutes:
  - route:
      labels:
        route: currency
  config:
    providers:
      auth0:
        issuer: "https://dev-64ktibmv.us.auth0.com/"
        audiences:
        - "https://httpbin/api"
        remote:
          url: "https://dev-64ktibmv.us.auth0.com/.well-known/jwks.json"
          destinationRef:
            ref:
              name: auth0
              namespace: dev-team
              cluster: mgmt-cluster
            kind: EXTERNAL_SERVICE
            port:
              number: 443
          enableAsyncFetch: true
EOF

# OIDC

export GLOO_GATEWAY=gloo-443-${INSTRUQT_PARTICIPANT_ID}.env.play.instruqt.com
( echo "cat <<EOF" ; cat $LOCAL_DIR/../../tracks/ext-auth-policy.yaml ; echo EOF ) | sh | kubectl apply -n dev-team -f -