#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


vault-install-helm(){
  # Install Vault on Kubernetes using Helm
  helm repo add hashicorp https://helm.releases.hashicorp.com
  helm repo update hashicorp

  helm install -n vault vault hashicorp/vault \
    --version=0.20.1 \
    --set "injector.enabled=false" \
    --set "server.dev.enabled=true" \
    --set "server.service.type=LoadBalancer" \
    --kube-context="${MGMT}" \
    --create-namespace \
    --wait

  # Wait for Vault to come up.
  # Don't use 'kubectl rollout' because Vault is a statefulset without a rolling deployment.
  kubectl --context="${MGMT}" wait --for=condition=Ready -n vault pod/vault-0
}

vault-enable-basic-auth(){

# Create admin policy
  kubectl --context="${MGMT}" exec -n vault vault-0 -- /bin/sh -c 'vault policy write admin - <<EOF
# Read system health check
path "sys/health"
{
  capabilities = ["read", "sudo"]
}

# Create and manage ACL policies broadly across Vault

# List existing policies
path "sys/policies/acl"
{
  capabilities = ["list"]
}

# Create and manage ACL policies
path "sys/policies/acl/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Enable and manage authentication methods broadly across Vault

# Manage auth methods broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create, update, and delete auth methods
path "sys/auth/*"
{
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth"
{
  capabilities = ["read"]
}

# Manage secrets engines
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secrets engines.
path "sys/mounts"
{
  capabilities = ["read"]
}

path "pki_int/*" {
capabilities = ["create", "read", "update", "delete", "list"]
}
# List, create, update, and delete key/value secrets
path "secret/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF'

  # Enable Vault userpass.
  kubectl --context="${MGMT}" exec -n vault vault-0 -- /bin/sh -c 'vault auth enable userpass'

  # Set the Kubernetes Auth config for Vault to the mounted token.
  kubectl --context="${MGMT}" exec -n vault vault-0 -- /bin/sh -c 'vault write auth/userpass/users/admin \
      password=admin \
      policies=admin'
}

vault-enable-kube-auth(){

  # Enable Vault auth for Kubernetes.
  kubectl --context="${MGMT}" exec -n vault vault-0 -- /bin/sh -c 'vault auth enable kubernetes'

  # Set the Kubernetes Auth config for Vault to the mounted token.
  kubectl --context="${MGMT}" exec -n vault vault-0 -- /bin/sh -c 'vault write auth/kubernetes/config \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'

  # Bind the istiod service account to the PKI policy.
  kubectl --context="${MGMT}" exec -n vault vault-0 -- /bin/sh -c 'vault write \
  auth/kubernetes/role/gen-int-ca-istio \
  bound_service_account_names=istiod-service-account \
  bound_service_account_namespaces=istio-system \
  policies=gen-int-ca-istio \
  ttl=2400h'

  # Initialize the Vault PKI.
  kubectl --context="${MGMT}" exec -n vault vault-0 -- /bin/sh -c 'vault secrets enable pki'
}

vault-setup-ca(){

  # TODO this only works if openssl is not using LibreSSL
  openssl req -new -newkey rsa:4096 -x509 -sha256 \
      -days 3650 -nodes -out $LOCAL_DIR/root-cert.pem -keyout $LOCAL_DIR/root-key.pem \
      -subj "/O=solo.io"

  # Set the Vault CA to the pem_bundle.
  kubectl --context="${MGMT}" exec -n vault vault-0 -- /bin/sh -c "vault write -format=json pki/config/ca pem_bundle=\"$(cat $LOCAL_DIR/root-key.pem $LOCAL_DIR/root-cert.pem)\""

  # Initialize the Vault intermediate cert path.
  kubectl --context="${MGMT}" exec -n vault vault-0 -- /bin/sh -c 'vault secrets enable -path pki_int pki'

  # Set the policy for the intermediate cert path.
  kubectl --context="${MGMT}" exec -n vault vault-0 -- /bin/sh -c 'vault policy write gen-int-ca-istio - <<EOF
  path "pki_int/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
  }
  path "pki/cert/ca" {
  capabilities = ["read"]
  }
  path "pki/root/sign-intermediate" {
  capabilities = ["create", "read", "update", "list"]
  }
  EOF'

  # Cert manager signing
  kubectl --context="${MGMT}" exec -n vault vault-0 -- /bin/sh -c 'vault policy write cert-manager-pki - <<EOF
  path "pki_int/*" {
  capabilities = ["read","list"]
  }
  path "pki/sign/*" {
  capabilities = ["create","update"]
  }
  path "pki/issue/*" {
  capabilities = ["create"]
  }
  EOF'

  rm $LOCAL_DIR/root-cert.pem $LOCAL_DIR/root-key.pem
}

# Install Everything
vault-install(){
  vault-enable-kube-auth
  vault-setup-ca
  vault-enable-basic-auth
}


