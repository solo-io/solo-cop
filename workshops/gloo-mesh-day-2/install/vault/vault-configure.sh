#!/bin/sh

set +ex

echo "VAULT endpoint: ${1}"

export VAULT_ADDR=${1}

apk update && apk add jq curl

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

vault login -method=userpass \
    username=admin \
    password=admin

# Root Certificate
vault secrets enable pki

vault secrets tune -max-lease-ttl=87600h pki

vault write -field=certificate pki/root/generate/internal \
     common_name="solo.io" \
     issuer_name="solo-io" \
     ttl=87600h > /root-ca.crt

vault write pki/config/urls \
     issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
     crl_distribution_points="$VAULT_ADDR/v1/pki/crl"

# Istio Intermediate
vault secrets enable -path=pki_int_istio pki

vault secrets tune -max-lease-ttl=43800h pki_int_istio

vault write -format=json  pki_int_istio/intermediate/generate/internal \
     common_name="Solo.io Istio CA Issuer" \
     issuer_name="solo-io-istio-issuer" \
     | jq -r '.data.csr' > /pki_intermediate_istio.csr

vault write -format=json pki/root/sign-intermediate \
     issuer_ref="solo-io" \
     csr=@/pki_intermediate_istio.csr \
     format=pem_bundle ttl="43800h" \
     | jq -r '.data.certificate' > /intermediate_istio.cert.pem

vault write  pki_int_istio/intermediate/set-signed certificate=@/intermediate_istio.cert.pem

## GLoo Intermediate
vault secrets enable -path=pki_int_gloo pki

vault secrets tune -max-lease-ttl=43800h pki_int_gloo

vault write -format=json  pki_int_gloo/intermediate/generate/internal \
     common_name="Solo.io Gloo CA Issuer" \
     issuer_name="solo-io-gloo-issuer" \
     | jq -r '.data.csr' > /pki_intermediate_gloo.csr

vault write -format=json pki/root/sign-intermediate \
     issuer_ref="solo-io" \
     csr=@/pki_intermediate_gloo.csr \
     format=pem_bundle ttl="43800h" \
     | jq -r '.data.certificate' > /intermediate_gloo.cert.pem

vault write pki_int_gloo/intermediate/set-signed certificate=@/intermediate_gloo.cert.pem

vault write pki_int_gloo/roles/gloo-issuer \
     allow_any_name=true \
     client_flag=true \
     server_flag=true \
     enforce_hostnames=false \
     max_ttl="720h"

# Create role for signing certs
vault policy write sign-certs -<<EOF
path "pki*"                        { capabilities = ["read", "list"] }
path "pki_int_istio/root/sign-intermediate"    { capabilities = ["create", "update"] }
path "pki_int_gloo/sign/gloo-issuer"   { capabilities = ["create", "update"] }
EOF

# Enable AppRole For cert manger

vault auth enable approle

vault write auth/approle/role/cert-manager secret_id_ttl=43800h policies=sign-certs

ROLE_ID=$(vault read auth/approle/role/cert-manager/role-id -format=json | jq -r '.data.role_id')
SECRET_ID=$(vault write -format=json -f auth/approle/role/cert-manager/secret-id | jq -r '.data.secret_id')

echo "Cert-Manager AppRole: $ROLE_ID SecretID: $SECRET_ID"

kubectl create configmap cert-manager-app-role -n vault --from-literal=role_id=$ROLE_ID --from-literal=secret_id=$SECRET_ID