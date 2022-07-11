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

vault secrets enable pki

vault secrets tune -max-lease-ttl=87600h pki

vault write -field=certificate pki/root/generate/internal \
     common_name="solo.io" \
     issuer_name="Solo Root Certificate" \
     ttl=87600h > /root-ca.crt


vault write pki/config/urls \
     issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
     crl_distribution_points="$VAULT_ADDR/v1/pki/crl"

vault secrets enable -path=pki_int pki

vault secrets tune -max-lease-ttl=43800h pki_int

vault write -format=json pki_int/intermediate/generate/internal \
     common_name="SOLO Istio CA Issuer" \
     issuer_name="solo.io-istio-issuer" \
     | jq -r '.data.csr' > /pki_intermediate.csr

vault write -format=json pki/root/sign-intermediate \
     issuer_ref="root-2022" \
     csr=@/pki_intermediate.csr \
     format=pem_bundle ttl="43800h" \
     | jq -r '.data.certificate' > /intermediate.cert.pem

vault write pki_int/intermediate/set-signed certificate=@/intermediate.cert.pem


vault write pki_int/roles/istio-ca-issuer \
     allowed_domains="solo.io" \
     allow_subdomains=true \
     max_ttl="720h"

# vault write pki_int/issue/istio-ca-issuer common_name="cluster1.solo.io" ttl="24h"

# create token for cert manager to use
TOKEN_RESPONSE=$(vault token create -policy=admin -format json)
TOKEN=$(echo $TOKEN_RESPONSE | jq -r '.auth.client_token')

kubectl create configmap cert-manager-token -n vault --from-literal=token=$TOKEN