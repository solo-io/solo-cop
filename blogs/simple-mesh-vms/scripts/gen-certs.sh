#!/bin/bash

echo "deploying cert-manager"

kubectl create namespace cert-manager || true
kubectl create namespace istio-system || true

kubectl apply -f config/cert-manager.yaml

sleep 40s

mkdir -p certs/root

openssl req -new -newkey rsa:4096 -x509 -sha256 \
        -days 3650 -nodes -out certs/root/istio-root-ca.crt -keyout certs/root/istio-root-ca.key \
        -config config/istio/istio-root-ca.conf

kubectl create secret generic istio-root-ca \
  --from-file=tls.key=certs/root/istio-root-ca.key \
  --from-file=tls.crt=certs/root/istio-root-ca.crt \
  --namespace cert-manager

kubectl apply -f- <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: istio-root-ca
  namespace: cert-manager
spec:
  ca:
    secretName: istio-root-ca
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cluster1-cacerts
  namespace: istio-system
spec:
  secretName: cluster1-cacerts
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
  # Issuer references are always required.
  issuerRef:
    kind: ClusterIssuer
    name: istio-root-ca
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: vm-cacerts
  namespace: istio-system
spec:
  secretName: vm-cacerts
  duration: 720h # 30d
  renewBefore: 360h # 15d
  commonName: vms.solo.io
  isCA: true
  usages:
    - digital signature
    - key encipherment
    - cert sign
  dnsNames:
    - vms.solo.io
  # Issuer references are always required.
  issuerRef:
    kind: ClusterIssuer
    name: istio-root-ca
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: vm-istio-ca
  namespace: istio-system
spec:
  ca:
    secretName: vm-cacerts
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: vm-proxy
  namespace: istio-system
spec:
  secretName: vm-proxy
  duration: 720h # 30d
  renewBefore: 360h # 15d
  commonName: envoy-proxy
  isCA: false
  usages:
    - client auth
    - server auth
  uris:
    - spiffe://vms.solo.io/ns/vm/sa/vm-1
  # Issuer references are always required.
  issuerRef:
    kind: Issuer
    name: vm-istio-ca
EOF

sleep 10s

WORK_DIR=certs

CLUSTER_DIR=$WORK_DIR/cluster1
mkdir -p $CLUSTER_DIR

# We need to build the cert files outselves including the chain so the secret can be in the correct format
kubectl get secret cluster1-cacerts -n istio-system -o json | jq '.data."tls.crt"' -r | base64 --decode > $CLUSTER_DIR/ca-cert.pem
kubectl get secret cluster1-cacerts -n istio-system -o json | jq '.data."tls.key"' -r | base64 --decode > $CLUSTER_DIR/ca-key.pem
kubectl get secret cluster1-cacerts -n istio-system -o json | jq '.data."ca.crt"' -r | base64 --decode > $CLUSTER_DIR/root-cert.pem
kubectl get secret cluster1-cacerts -n istio-system -o json | jq '.data."tls.crt"' -r | base64 --decode > $CLUSTER_DIR/cert-chain.pem
kubectl get secret cluster1-cacerts -n istio-system -o json | jq '.data."ca.crt"' -r | base64 --decode >> $CLUSTER_DIR/cert-chain.pem

VM_DIR=$WORK_DIR/vm
mkdir $VM_DIR

kubectl get secret vm-proxy -n istio-system -o json | jq '.data."tls.crt"' -r | base64 --decode > $VM_DIR/cert.pem
kubectl get secret vm-proxy -n istio-system -o json | jq '.data."tls.key"' -r | base64 --decode > $VM_DIR/key.pem
kubectl get secret vm-proxy -n istio-system -o json | jq '.data."ca.crt"' -r | base64 --decode > $VM_DIR/ca-cert.pem


kubectl create secret generic cacerts -n istio-system \
      --from-file=$CLUSTER_DIR/ca-cert.pem \
      --from-file=$CLUSTER_DIR/ca-key.pem \
      --from-file=$CLUSTER_DIR/root-cert.pem \
      --from-file=$CLUSTER_DIR/cert-chain.pem