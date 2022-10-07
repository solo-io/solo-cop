# Hosted Vault Setup

1. Deploy Vault server

2. Configure local vault cli
```sh
export VAULT_ADDR="https://vault-cluster-public-vault-681de3cb.7aa5474d.z1.hashicorp.cloud:8200"; export VAULT_NAMESPACE="admin"
export VAULT_TOKEN=hvs.CAESIBO-dK05F9uCGOQepCGsyKyH16BUuOvCqi0rT_-EH4McGicKImh2cy5hWkNncU45djZMMGpiWkYwSjRzOGpVeW0uY212MDIQlwE

vault status
```

3. Setup Root Cert (https://learn.hashicorp.com/tutorials/vault/pki-engine)
```sh
vault secrets enable pki
vault secrets tune -max-lease-ttl=87600h pki

# Generate Root Certificate and Store
vault write -field=certificate pki/root/generate/internal \
     common_name="solo.io" \
     issuer_name="solo-io-issuer" \
     ttl=87600h > root-ca.crt

vault write pki/config/urls \
     issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
     crl_distribution_points="$VAULT_ADDR/v1/pki/crl"

```

4. Setup Istio Intermediate

```sh
vault secrets enable -path=pki_int_istio pki

vault secrets tune -max-lease-ttl=43800h pki_int_istio

vault write -format=json  pki_int_istio/intermediate/generate/internal \
     common_name="Solo.io Istio CA Issuer" \
     issuer_name="solo-io-istio-issuer" \
     | jq -r '.data.csr' > pki_intermediate_istio.csr

vault write -format=json pki/root/sign-intermediate \
     issuer_ref="solo-io-issuer" \
     csr=@pki_intermediate_istio.csr \
     format=pem_bundle ttl="43800h" \
     | jq -r '.data.certificate' > intermediate_istio.cert.pem   

#Once the CSR is signed and the root CA returns a certificate, it can be imported back into Vault.
vault write pki_int_istio/intermediate/set-signed certificate=@intermediate_istio.cert.pem
#Key                 Value
#---                 -----
#imported_issuers    [71c861bd-d0f1-856f-e242-c4b8ebb8ddab d9570b2b-d7a0-efa0-8ecf-5d08c7eb497b]
#imported_keys       <nil>
#mapping             map[71c861bd-d0f1-856f-e242-c4b8ebb8ddab:994a85ef-b2fe-60e0-95c0-352c9c60a752 d9570b2b-d7a0-efa0-8ecf-5d08c7eb497b:]
```

5. Create Gloo Intermediate

```sh
vault secrets enable -path=pki_int_gloo pki

vault secrets tune -max-lease-ttl=43800h pki_int_gloo

vault write -format=json  pki_int_gloo/intermediate/generate/internal \
     common_name="Solo.io Gloo CA Issuer" \
     issuer_name="solo-io-gloo-issuer" \
     | jq -r '.data.csr' > pki_intermediate_gloo.csr

vault write -format=json pki/root/sign-intermediate \
     issuer_ref="solo-io-issuer" \
     csr=@pki_intermediate_gloo.csr \
     format=pem_bundle ttl="43800h" \
     | jq -r '.data.certificate' > intermediate_gloo.cert.pem

vault write pki_int_gloo/intermediate/set-signed certificate=@intermediate_gloo.cert.pem

vault write pki_int_gloo/roles/gloo-issuer \
     allow_any_name=true \
     client_flag=true \
     server_flag=true \
     enforce_hostnames=false \
     max_ttl="8544h"
```

6. Create cert manager role

```sh
vault policy write cert-manager -<<EOF
path "pki*"                        { capabilities = ["read", "list"] }
path "pki_int_istio/root/sign-intermediate"    { capabilities = ["create", "update"] }
path "pki_int_gloo/sign/gloo-issuer"   { capabilities = ["create", "update"] }
EOF
```
 7. V ault auth enable approle

```sh
vault write auth/approle/role/cert-manager secret_id_ttl=43800h policies=sign-certs

ROLE_ID=$(vault read auth/approle/role/cert-manager/role-id -format=json | jq -r '.data.role_id')
SECRET_ID=$(vault write -format=json -f auth/approle/role/cert-manager/secret-id | jq -r '.data.secret_id')

echo "Cert-Manager AppRole: $ROLE_ID SecretID: $SECRET_ID"
```