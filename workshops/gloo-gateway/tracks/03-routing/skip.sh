#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Expose currency app

kubectl apply -f - <<'EOF'
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: currency
  namespace: dev-team
spec:
  weight: 100
  workloadSelectors: []
  http:
    - matchers:
      - uri:
          prefix: /hipstershop.CurrencyService/Convert
      name: currency
      labels:
        route: currency
      forwardTo:
        destinations:
          - ref:
              name: currencyservice
              namespace: backend-apis
            port:
              number: 7000
EOF

# External endpoint

kubectl apply -f - <<'EOF'
apiVersion: networking.gloo.solo.io/v2
kind: ExternalEndpoint
metadata:
  name: httpbin
  namespace: dev-team
  labels:
    external-service: httpbin
spec:
  address: httpbin.org
  ports:
    - name: http
      number: 80
    - name: https
      number: 443
---
apiVersion: networking.gloo.solo.io/v2
kind: ExternalService
metadata:
  name: httpbin
  namespace: dev-team
spec:
  selector:
    external-service: httpbin
  hosts:
  - httpbin.org
  ports:
  - name: http
    number: 80
    protocol: HTTP
  - name: https
    number: 443
    protocol: HTTPS
    clientsideTls: {}   ### upgrade outbound call to HTTPS
EOF

# Route Table external service

kubectl apply -f - <<'EOF'
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: httpbin
  namespace: dev-team
spec:
  weight: 150
  workloadSelectors: []
  http:
    - matchers:
      - uri:
          prefix: /httpbin
      name: httpbin-all
      labels:
        route: httpbin
      forwardTo:
        pathRewrite: /
        destinations:
        - ref:
            name: httpbin
          port:
            number: 443
          kind: EXTERNAL_SERVICE
EOF