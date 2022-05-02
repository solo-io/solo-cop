#!/bin/bash

# Relay Root CA
openssl req -new -newkey rsa:4096 -x509 -sha256 \
        -days 3650 -nodes -out secrets/relay-root-ca.crt -keyout secrets/relay-root-ca.key \
        -subj "/CN=relay-root-ca"

# Relay signing cert
# Generate private key
openssl genrsa -out secrets/relay-signing-cert.key 2048
# Create CSR
openssl req -new -key secrets/relay-signing-cert.key -out secrets/relay-signing-cert.csr  -config secrets/relay-signing-cert.conf

# Sign with root ca
openssl x509 -req \
  -days 3650 \
  -CA secrets/relay-root-ca.crt \
  -CAkey secrets/relay-root-ca.key \
  -set_serial 0 \
  -in secrets/relay-signing-cert.csr \
  -out secrets/relay-signing-cert.crt \
  -extensions req_ext \
  -extfile secrets/relay-signing-cert.conf

# Generate and sign the gloo-mesh-mgmt-server tls server secret
openssl genrsa -out "secrets/gloo-mesh-mgmt-server.key" 2048
# Generate gloo-mesh-mgmt-server CSR
openssl req -new -key "secrets/gloo-mesh-mgmt-server.key" -out secrets/gloo-mesh-mgmt-server.csr -subj "/CN=gloo-mesh-mgmt-server" -config "secrets/gloo-mesh-mgmt-server.conf"

# sign mgmt server cert
openssl x509 -req \
  -days 3650 \
  -CA secrets/relay-root-ca.crt -CAkey secrets/relay-root-ca.key \
  -set_serial 0 \
  -in secrets/gloo-mesh-mgmt-server.csr -out secrets/gloo-mesh-mgmt-server.crt \
  -extensions v3_req -extfile "secrets/gloo-mesh-mgmt-server.conf"