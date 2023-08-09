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

  until kubectl get service/vault --context $MGMT -n vault --output=jsonpath='{.status.loadBalancer}' | grep "ingress"; do : ; done

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
  capabilities = ["read","list"]
}
path "pki_int/*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}
# List, create, update, and delete key/value secrets
path "secret/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
# Work with pki secrets engine
path "pki*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}
EOF'

  # Enable Vault userpass.
  kubectl --context="${MGMT}" exec -n vault vault-0 -- /bin/sh -c 'vault auth enable userpass'

  # Set the Kubernetes Auth config for Vault to the mounted token.
  kubectl --context="${MGMT}" exec -n vault vault-0 -- /bin/sh -c 'vault write auth/userpass/users/admin \
password=admin \
policies=admin'
}

vault-setup-istio-pki() {
  kubectl apply --context $MGMT -f $LOCAL_DIR/vault-setup-pod.yaml
  kubectl wait --for=condition=ready pod -l app=vault-setup -n vault --context $MGMT --timeout 60s

  kubectl --context $MGMT -n vault cp $LOCAL_DIR/vault-configure.sh vault-setup:/tmp/vault-configure.sh
  kubectl exec --context $MGMT -n vault -it vault-setup -- /tmp/vault-configure.sh http://vault.vault.svc.cluster.local:8200
}

vault-install-helm
vault-enable-basic-auth
vault-setup-istio-pki