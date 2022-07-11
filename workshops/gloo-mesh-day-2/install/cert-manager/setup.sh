#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

kubectl create ns istio-system --context $MGMT
kubectl create ns istio-system --context $CLUSTER1
kubectl create ns istio-system --context $CLUSTER2

kubectl --context ${MGMT} apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml
kubectl --context ${CLUSTER1} apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml
kubectl --context ${CLUSTER2} apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml

kubectl wait deployment --for condition=Available=True -n cert-manager --context $MGMT --all
kubectl wait deployment --for condition=Available=True -n cert-manager --context $CLUSTER1 --all
kubectl wait deployment --for condition=Available=True -n cert-manager --context $CLUSTER2 --all


TOKEN=$(kubectl get configmap -n vault --context $MGMT cert-manager-token -o json | jq -r '.data.token')

kubectl create secret generic vault-token -n istio-system --context $MGMT --from-literal=token=$TOKEN
kubectl create secret generic vault-token -n istio-system --context $CLUSTER1 --from-literal=token=$TOKEN
kubectl create secret generic vault-token -n istio-system --context $CLUSTER2 --from-literal=token=$TOKEN

kubectl apply --context $MGMT -f- <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: vault-issuer
  namespace: istio-system
spec:
  vault:
    path: v1/root/istio-ca-issuer
    server: $VAULT_ADDR
    auth:
      tokenSecretRef:
          name: vault-token
          key: token
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: mgmt-cacerts
  namespace: istio-system
spec:
  secretName: cacerts
  duration: 720h # 30d
  renewBefore: 360h # 15d
  commonName: mgmt.solo.io
  isCA: true
  usages:
    - digital signature
    - key encipherment
    - cert sign
  dnsNames:
    - mgmt.solo.io
  issuerRef:
    kind: Issuer
    name: vault-issuer
EOF


kubectl apply --context $CLUSTER1 -f- <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: vault-issuer
  namespace: istio-system
spec:
  vault:
    path: pki_int/sign/istio-ca-issuer
    server: $VAULT_ADDR
    auth:
      tokenSecretRef:
          name: vault-token
          key: token
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cluster1-cacerts
  namespace: istio-system
spec:
  secretName: cacerts
  duration: 720h # 30d
  renewBefore: 360h # 15d
  commonName: cluster1.solo.io
  isCA: true
  usages:
    - digital signature
    - key encipherment
    - cert sign
  dnsNames:
    - cluster1.solo.io
  issuerRef:
    kind: Issuer
    name: vault-issuer
EOF

kubectl apply --context $CLUSTER2 -f- <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: vault-issuer
  namespace: istio-system
spec:
  vault:
    path: pki_int/sign/istio-ca-issuer
    server: $VAULT_ADDR
    auth:
      tokenSecretRef:
          name: vault-token
          key: token
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cluster2-cacerts
  namespace: istio-system
spec:
  secretName: cacerts
  duration: 720h # 30d
  renewBefore: 360h # 15d
  commonName: cluster2.solo.io
  isCA: true
  usages:
    - digital signature
    - key encipherment
    - cert sign
  dnsNames:
    - cluster2.solo.io
  issuerRef:
    kind: Issuer
    name: vault-issuer
EOF