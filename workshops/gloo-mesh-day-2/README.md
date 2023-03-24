![Gloo Platform](images/gloo-mesh-2.0-banner.png)

# <center>Gloo Platform Day 2 Workshop</center>

## Table of Contents

* [Introduction](#introduction)
* [Lab 1 - Deploy Kubernetes clusters](#Lab-1)
* [Lab 2 - PKI / Vault and Cert Manager](#Lab-2)
* [Lab 3 - Install Gloo Platform](#Lab-3)
* [Lab 4 - High Availability Management Plane](#Lab-4)
* [Lab 5 - Migrate To Managed Istio](#Lab-4)

## Introduction <a name="introduction"></a>

![Day 2 Workshop Architecture](images/day2-arch.png)

The day 2 Gloo Platform workshop is all about the best practices and architectures to make your mutli-cluster deployment resilient, secure, and maintainable for the long term. This workshop was created based upon how Solo.io customers have been able to successfully run Gloo in Production as well as the knowledge from our Istio experts.

High level best practices:
* Use helm and GitOps for deploying infrastructure to kubernetes
* Keep your PKI secure and rotate certificates
* Scale your components for resiliency

### Want to learn more about Gloo Platform?

You can find more information about Gloo Platform in the official documentation:

[https://docs.solo.io/gloo-mesh/latest/](https://docs.solo.io/gloo-mesh/latest/)

## Begin

To get started with this workshop, clone this repo.

```sh
git clone https://github.com/solo-io/solo-cop.git
cd solo-cop/workshops/gloo-mesh-demo
```

Set these environment variables which will be used throughout the workshop.

```sh
# Used to enable Gloo (please ask for a trial license key)
export GLOO_PLATFORM_LICENSE_KEY=<licence_key>
export GLOO_PLATFORM_VERSION=v2.2.5
export ISTIO_IMAGE_REPO=us-docker.pkg.dev/gloo-mesh/istio-workshops
export ISTIO_IMAGE_TAG=1.16.3-solo
export ISTIO_VERSION=1.16.3
export ISTIO_REVISION=1-16
```

## Lab 1 - Configure/Deploy the Kubernetes clusters <a name="Lab-1"></a>

You will need to create two Kubernetes Clusters. One will serve as the Management cluster in which the Gloo Platform server will be deployed. The second cluster will be a workload cluster.

This workshop can run on many different Kubernetes distributions such as EKS, GKE, OpenShift, RKE, etc or you can 
* [create local k3d clusters](infra/k3d/README.md)
* [create eks clusters using eksctl](infra/eks/README.md).

Set these environment variables to represent your two clusters.
```sh
export MGMT=mgmt
export CLUSTER1=cluster1
```

Rename the kubectl config contexts of each of your two clusters to `mgmt`, `cluster1` respectively.

```sh
# UPDATE <context-to-rename> BEFORE APPLYING
kubectl config rename-context <context-to-rename> ${MGMT} 
kubectl config rename-context <context-to-rename> ${CLUSTER1} 
``` 

## Lab 2 - PKI / Vault and Cert Manager<a name="Lab-2"></a>

Gloo and Istio heavily rely on TLS certificates to facilitate safe and secure communitcation. Gloo Platform uses mutual tls authentication for communication between the Server and the Agents. Istio requires an Intermediate Signing CA so that it can issue workload certificates to each of the mesh enabled services. These workload certificates encrypt and authenticate traffic between each of your microservices.

It is important to design and implement a secure and reliable Public Key Infrastructure (PKI) that Gloo and Istio can rely on. In this workload we have chosen `Vault` and `cert-manager` as the PKI due to their versatility and reliability for managing certificates. 

![PKI Deployment](images/pki-arch.png)

### Vault

Vault is not only a reliable secret store, but also great at managing and issuing certificates. In this workshop Vault will be responsible for holding `root` certificate as well as two intermediates, one for Istio, the other for Gloo.

![PKI Deployment](images/vault-certs.png)

* Deploy vault and automatically configure it to have a root certificate and 2 intermediates.

```sh
./install/vault/setup.sh
```

* Save the Vault address to be later used by `cert-manager`

```sh
export VAULT_ADDR=http://$(kubectl --context ${MGMT} -n vault get svc vault -o jsonpath='{.status.loadBalancer.ingress[0].*}'):8200

printf "\n\nVault available at: $VAULT_ADDR\n"
```

* Generate a token to give to cert-manager

```sh
export VAULT_APPROLE_ID=$(kubectl get configmap -n vault --context $MGMT cert-manager-app-role -o json | jq -r '.data.role_id')
export VAULT_APPROLE_SECRET_ID=$(kubectl get configmap -n vault --context $MGMT cert-manager-app-role -o json | jq -r '.data.secret_id')

printf "\n\nYour cert-manager AppRole RoleID: $VAULT_APPROLE_ID\nSecretID: $VAULT_APPROLE_SECRET_ID"
```

### Cert Manager

This workshop chose cert manager as the last-mile certificate management solution for a number of reasons. First, it is the most widely used Kubernetes based solution. Secondly, it natively integrates with a number of different issuing systems such as [AWS Private CA](https://github.com/cert-manager/aws-privateca-issuer), [Google Cloud CA](https://github.com/jetstack/google-cas-issuer) and [Vault](https://cert-manager.io/docs/configuration/vault/). Finally, cert-manager also creates certificates in the form of kubernetes secrets which are compatible with both Istio and Gloo Platform. It also has the ability to automatically rotate them when they are nearing their end of life.

![Cert Manager Backends](./images/cert-manager-pki.png)

* Deploy cert-manager to both the `mgmt` and `cluster1` clusters

```sh
kubectl --context ${MGMT} apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml
kubectl --context ${CLUSTER1} apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml

kubectl wait deployment --for condition=Available=True -n cert-manager --context $MGMT --all
kubectl wait deployment --for condition=Available=True -n cert-manager --context $CLUSTER1 --all
```

* Create the kubernetes secret containing the Vault token in each `cert-manager` namespace. This will be used by cert-manager to authenticate with Vault

```sh
kubectl create secret generic cert-manager-vault-approle -n cert-manager --context $MGMT --from-literal=secretId=$VAULT_APPROLE_SECRET_ID
kubectl create secret generic cert-manager-vault-approle -n cert-manager --context $CLUSTER1 --from-literal=secretId=$VAULT_APPROLE_SECRET_ID
```

* Create a ClusterIssuer for Gloo and Istio in `mgmt` cluster

```yaml
kubectl apply --context $MGMT -f- <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: vault-issuer-istio
  namespace: cert-manager
spec:
  vault:
    path: pki_int_istio/root/sign-intermediate
    server: $VAULT_ADDR
    # namespace: admin   # Required for multi-tenant vaukt or HCP CLoud
    auth:
      appRole:
        path: approle
        roleId: $VAULT_APPROLE_ID
        secretRef:
          name: cert-manager-vault-approle
          key: secretId
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: vault-issuer-gloo
  namespace: cert-manager
spec:
  vault:
    path: pki_int_gloo/sign/gloo-issuer
    server: $VAULT_ADDR
    # namespace: admin   # Required for multi-tenant vaukt or HCP CLoud
    auth:
      appRole:
        path: approle
        roleId: $VAULT_APPROLE_ID
        secretRef:
          name: cert-manager-vault-approle
          key: secretId
EOF
```

* Create a ClusterIssuer for Gloo and Istio in `cluster1` cluster

```yaml
kubectl apply --context ${CLUSTER1} -f- <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: vault-issuer-istio
  namespace: cert-manager
spec:
  vault:
    path: pki_int_istio/root/sign-intermediate ## This path allows ca: TRUE certificaets
    server: $VAULT_ADDR
    # namespace: admin   # Required for multi-tenant vaukt or HCP CLoud
    auth:
      appRole:
        path: approle
        roleId: $VAULT_APPROLE_ID
        secretRef:
          name: cert-manager-vault-approle
          key: secretId
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: vault-issuer-gloo
  namespace: cert-manager
spec:
  vault:
    path: pki_int_gloo/sign/gloo-issuer ## This path is for client/server certificates
    server: $VAULT_ADDR
    # namespace: admin   # Required for multi-tenant vaukt or HCP CLoud
    auth:
      appRole:
        path: approle
        roleId: $VAULT_APPROLE_ID
        secretRef:
          name: cert-manager-vault-approle
          key: secretId
EOF
```

## Gloo Platform Certificate Setup

Gloo uses client/server TLS certificates to securely communicate between the server and agents. This prevents non gloo applications from inadvertantly connecting to the Gloo server and accessing its information.

![Gloo Certs](./images/gloo-certs.png)

* Create gloo-mesh namespaces

```sh
kubectl create namespace gloo-mesh --context $MGMT
kubectl create namespace gloo-mesh --context $CLUSTER1
```

* Generate a certificate for the `gloo-mesh-mgmt-server` service

```yaml
kubectl --context $MGMT apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: gloo-server
  namespace: gloo-mesh
spec:
  commonName: gloo-server
  dnsNames:
    - "*.gloo-mesh"
  duration: 8760h0m0s   ### 1 year life
  renewBefore: 8736h0m0s
  issuerRef:
    kind: ClusterIssuer
    name: vault-issuer-gloo
  secretName: gloo-server-tls-cert
  usages:
    - server auth
    - client auth
  privateKey:
    algorithm: "RSA"
    size: 4096
---
kind: Certificate
apiVersion: cert-manager.io/v1
metadata:
  name: gloo-agent
  namespace: gloo-mesh
spec:
  commonName: gloo-agent
  dnsNames:
    # Must match the cluster name used in the helm chart install
    - "mgmt-cluster"
  duration: 8760h0m0s   ### 1 year life
  renewBefore: 8736h0m0s
  issuerRef:
    kind: ClusterIssuer
    name: vault-issuer-gloo
  secretName: gloo-agent-tls-cert
  usages:
    - digital signature
    - key encipherment
    - client auth
    - server auth
  privateKey:
    algorithm: "RSA"
    size: 4096
EOF
```

* Generate a client certificate for the `gloo-agent`

```yaml
kubectl apply --context $CLUSTER1 -f - << EOF
kind: Certificate
apiVersion: cert-manager.io/v1
metadata:
  name: gloo-agent
  namespace: gloo-mesh
spec:
  commonName: gloo-agent
  dnsNames:
    # Must match the cluster name used in the helm chart install
    - "$CLUSTER1"
  duration: 8760h0m0s   ### 1 year life
  renewBefore: 8736h0m0s
  issuerRef:
    kind: ClusterIssuer
    name: vault-issuer-gloo
  secretName: gloo-agent-tls-cert
  usages:
    - digital signature
    - key encipherment
    - client auth
    - server auth
  privateKey:
    algorithm: "RSA"
    size: 4096
EOF
```

* Verify secrets

```sh
kubectl get secret gloo-server-tls-cert -n gloo-mesh --context $MGMT
kubectl get secret gloo-agent-tls-cert -n gloo-mesh --context $MGMT
kubectl get secret gloo-agent-tls-cert -n gloo-mesh --context $CLUSTER1
```

## Install Gloo <a name="Lab-3"></a>

Gloo consists of a centralized management server to which agents running on each of the workload clusters connect. The recommended way to install Gloo in production is via `helm`. Helm was chosen because of the amount of support it has with various GitOps based deployment solutions. Many of our customers today use `ArgoCD` to deploy Gloo. For more see [GitOps with ArgoCD and Gloo](https://www.solo.io/blog/gitops-with-argo-cd-and-gloo-mesh-part-1/)

![Gloo Architecture](./images/gloo.png)

* Add Gloo Helm charts to your repository

```sh
helm repo add gloo-mesh-agent https://storage.googleapis.com/gloo-mesh-enterprise/gloo-mesh-agent
helm repo add gloo-mesh-enterprise https://storage.googleapis.com/gloo-mesh-enterprise/gloo-mesh-enterprise 
helm repo update
```

* View the default management plane values

```sh
helm show values gloo-mesh-enterprise/gloo-mesh-enterprise --version $GLOO_PLATFORM_VERSION
```

* View the default control plane values

```sh
helm show values gloo-mesh-agent/gloo-mesh-agent --version $GLOO_PLATFORM_VERSION
```

## Install Gloo Platform <a name="Lab-3"></a>

Gloo Platform can be installed using Helm. It is recommended to use deploy Gloo Platform via a CI/CD orchectrator such as ArgoCD or Flux.

* Install the management plane via helm. The default prometheus deployment will be disabled in favor of a more production based install. The automatic certificate generation is also disabled as it is now handled by cert-manager. 

```sh
helm upgrade --install gloo-mesh-enterprise gloo-mesh-enterprise/gloo-mesh-enterprise \
  --version=${GLOO_PLATFORM_VERSION} \
  --set glooMeshLicenseKey=$GLOO_PLATFORM_LICENSE_KEY \
  --set glooTrialLicenseKey=$GLOO_PLATFORM_LICENSE_KEY \
  --set glooGatewayLicenseKey=$GLOO_PLATFORM_LICENSE_KEY \
  --kube-context ${MGMT} \
  --namespace gloo-mesh \
  --set glooMeshMgmtServer.relay.disableTokenGeneration=true \
  --set glooMeshMgmtServer.relay.disableCa=true \
  --set glooMeshMgmtServer.relay.disableCaCertGeneration=true \
  --set glooMeshMgmtServer.relay.tlsSecret.name=gloo-server-tls-cert \
  --set prometheus.enabled=false \
  --wait
```

* Register mgmt and cluster1 with the management plane so that the connecting agents will be trusted

```yaml
kubectl apply --context $MGMT -f- <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: KubernetesCluster
metadata:
  name: mgmt-cluster
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
---
apiVersion: admin.gloo.solo.io/v2
kind: KubernetesCluster
metadata:
  name: cluster1
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
EOF
```

* Get the mgmt plane address

```sh
MGMT_INGRESS_ADDRESS=$(kubectl get svc -n gloo-mesh gloo-mesh-mgmt-server --context $MGMT -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
MGMT_INGRESS_PORT=$(kubectl -n gloo-mesh get service gloo-mesh-mgmt-server --context $MGMT -o jsonpath='{.spec.ports[?(@.name=="grpc")].port}')
RELAY_ADDRESS=${MGMT_INGRESS_ADDRESS}:${MGMT_INGRESS_PORT}
echo "RELAY_ADDRESS: ${RELAY_ADDRESS}"
```

* Install a Gloo agent on the management plane so we later can add and manage Gloo Gateway on it.

```sh
# create a dummy token, gloo platform requires the token to exist
kubectl create secret generic relay-identity-token-secret --from-literal=token=not-used -n gloo-mesh --context $MGMT
helm upgrade --install gloo-mesh-agent gloo-mesh-agent/gloo-mesh-agent \
  --kube-context=${MGMT} \
  --namespace gloo-mesh \
  --set relay.serverAddress=${RELAY_ADDRESS} \
  --set cluster=mgmt-cluster \
  --set relay.clientTlsSecret.name=gloo-agent-tls-cert \
  --version ${GLOO_PLATFORM_VERSION} \
  --wait
```

* Install a Gloo agent on the remote cluster.

```sh
# create a dummy token, gloo platform requires the token to exist
kubectl create secret generic relay-identity-token-secret --from-literal=token=not-used -n gloo-mesh --context $CLUSTER1
helm upgrade --install gloo-mesh-agent gloo-mesh-agent/gloo-mesh-agent \
  --kube-context=${CLUSTER1} \
  --namespace gloo-mesh \
  --set relay.serverAddress=${RELAY_ADDRESS} \
  --set cluster=${CLUSTER1} \
  --set relay.clientTlsSecret.name=gloo-agent-tls-cert \
  --version ${GLOO_PLATFORM_VERSION} \
  --wait
```

* Since Prometheus has not been installed yet we will have to verify the agents are connected by looking at the stats emitted by the management plane.
```sh
kubectl port-forward -n gloo-mesh deploy/gloo-mesh-mgmt-server --context $MGMT 9091:9091

curl -sS localhost:9091/metrics | grep relay_push_clients_connected
```

* Expected Output
```sh
▶ curl -sS localhost:9091/metrics | grep relay_push_clients_connected
# HELP relay_push_clients_connected Current number of connected Relay push clients (Relay Agents).
# TYPE relay_push_clients_connected gauge
relay_push_clients_connected{cluster="cluster1"} 1
relay_push_clients_connected{cluster="mgmt-cluster"} 1
```

## Install Istio <a name="Lab-4"></a>

### Istio Certificate Setup

As stated above, Istio requries an Intermediate Signing CA so that it can issue workload certificates. Each remote cluster should have an Intermediate Signing CA that is rooted in the same trust chain if you want to facilitate cross cluster communication. 

![Istio Certs](./images/istio-certs.png)

* Create istio-system namespaces

```sh
kubectl create namespace istio-system --context $MGMT
kubectl create namespace istio-system --context $CLUSTER1
```

* Create Istio `cacerts` certificate in the `mgmt` cluster

```yaml
kubectl apply --context $MGMT -f- <<EOF
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
    kind: ClusterIssuer
    name: vault-issuer-istio
EOF
```

* Create Istio `cacerts` certificate in the `cluster1` cluster

```yaml
kubectl apply --context $CLUSTER1 -f- <<EOF
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
    kind: ClusterIssuer
    name: vault-issuer-istio
EOF
```

* Verify Secrets are created

```sh
kubectl get secret -n istio-system cacerts --context $MGMT
kubectl get secret -n istio-system cacerts --context $CLUSTER1
```

Istio now recommends using `helm` to install its components. The helm charts are broken up into a few distinct charts. This makes it easier to manage istio and upgrade the component individually when needed.

Istio charts:
* istio/base - Istio custom resource definitions
* istio/istiod - Istio control plane installation
* istio/gateway - Single Istio gateway (ingress/eastwest/egress) installation

There are a number of recommended best practices to employ when installing Istio for production. This workshop does not implement them all but does setup the architecture enabling the end user to iterate later on.

Recommended architecture best practices:
* Use `helm` based deployments
* Use revisions to verion the control plane and gateways
* Deploy ingress and eastwest to their own namespaces
* Use PKI to provision `cacerts`
* Monitor istiod and gateways health via observability tools

### Installation

Istio will be installed into both clusters. In a previous step, a gloo mesh agent was installed in the `mgmt` cluster. This was so that the centralized management tools could be exposed via an Istio gateway to the end user which will be done in a later step. This workshop uses a Solo.io specific build of Istio that has solo addon filters that enable such features as `external authorization`, `rate limiting`, and `GraphQL`.

![Istio Architecture](./images/istio-arch.png)

Lets begin
* Add the Istio charts repository

```sh
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
```

* Install Istio CRDs to each cluster

```sh
helm upgrade --install istio-base istio/base \
  -n istio-system \
  --version ${ISTIO_VERSION} \
  --kube-context ${MGMT} \
  --create-namespace

helm upgrade --install istio-base istio/base \
  -n istio-system \
  --version ${ISTIO_VERSION} \
  --kube-context ${CLUSTER1} \
  --create-namespace
```

* Install Istio control plane to the `mgmt` cluster

```yaml
helm upgrade --install istiod-${ISTIO_REVISION} istio/istiod \
  --set revision=${ISTIO_REVISION} \
  --set global.hub=${ISTIO_IMAGE_REPO} \
  --set global.tag=${ISTIO_IMAGE_TAG} \
  --version ${ISTIO_VERSION} \
  --namespace istio-system \
  --kube-context ${MGMT} \
  --wait \
  -f- <<EOF
meshConfig:
  # The trust domain corresponds to the trust root of a system. 
  # For Gloo this should be the name of the cluster that cooresponds with the CA certificate CommonName identity
  trustDomain: mgmt-cluster
  # enable access logging to standard output
  accessLogFile: /dev/stdout
  defaultConfig:
    # wait for the istio-proxy to start before application pods
    holdApplicationUntilProxyStarts: true
    # enable Gloo metrics service (required for Gloo UI)
    envoyMetricsService:
      address: gloo-mesh-agent.gloo-mesh:9977
      # enable Gloo accesslog service (required for Gloo Access Logging)
    envoyAccessLogService:
      address: gloo-mesh-agent.gloo-mesh:9977
    proxyMetadata:
      # Enable Istio agent to handle DNS requests for known hosts
      # Unknown hosts will automatically be resolved using upstream dns servers in resolv.conf
      # (for proxy-dns)
      ISTIO_META_DNS_CAPTURE: "true"
      # Enable automatic address allocation (for proxy-dns)
      ISTIO_META_DNS_AUTO_ALLOCATE: "true"
      # Used for gloo mesh metrics aggregation
      # should match trustDomain (required for Gloo UI)
      GLOO_MESH_CLUSTER_NAME: mgmt-cluster
pilot:
  env:
    # Allow multiple trust domains (Required for Gloo east/west routing)
    PILOT_SKIP_VALIDATE_TRUST_DOMAIN: "true"
    # Reload cacerts when cert-manager changes it
    AUTO_RELOAD_PLUGIN_CERTS: "true"
EOF
```

* Install Istio control plane to the `cluster1` cluster

```yaml
helm upgrade --install istiod-${ISTIO_REVISION} istio/istiod \
  --set revision=${ISTIO_REVISION} \
  --set global.hub=${ISTIO_IMAGE_REPO} \
  --set global.tag=${ISTIO_IMAGE_TAG} \
  --version ${ISTIO_VERSION} \
  --namespace istio-system \
  --kube-context ${CLUSTER1} \
  --wait \
  -f- <<EOF
meshConfig:
  # The trust domain corresponds to the trust root of a system. 
  # For Gloo this should be the name of the cluster that cooresponds with the CA certificate CommonName identity
  trustDomain: cluster1
  # enable access logging to standard output
  accessLogFile: /dev/stdout
  defaultConfig:
    # wait for the istio-proxy to start before application pods
    holdApplicationUntilProxyStarts: true
    # enable Gloo metrics service (required for Gloo UI)
    envoyMetricsService:
      address: gloo-mesh-agent.gloo-mesh:9977
      # enable Gloo accesslog service (required for Gloo Access Logging)
    envoyAccessLogService:
      address: gloo-mesh-agent.gloo-mesh:9977
    proxyMetadata:
      # Enable Istio agent to handle DNS requests for known hosts
      # Unknown hosts will automatically be resolved using upstream dns servers in resolv.conf
      # (for proxy-dns)
      ISTIO_META_DNS_CAPTURE: "true"
      # Enable automatic address allocation (for proxy-dns)
      ISTIO_META_DNS_AUTO_ALLOCATE: "true"
      # Used for gloo mesh metrics aggregation
      # should match trustDomain (required for Gloo UI)
      GLOO_MESH_CLUSTER_NAME: cluster1
pilot:
  env:
    # Allow multiple trust domains (Required for Gloo east/west routing)
    PILOT_SKIP_VALIDATE_TRUST_DOMAIN: "true"
    # Reload cacerts when cert-manager changes it
    AUTO_RELOAD_PLUGIN_CERTS: "true"
EOF
```

* Verify that Istio is using the plugged in certs `kubectl logs --context ${MGMT} -l app=istiod -n istio-system --tail 100`
```sh
2022-10-05T19:50:32.288662Z    info    Using kubernetes.io/tls secret type for signing ca files
2022-10-05T19:50:32.288667Z    info    Use plugged-in cert at etc/cacerts/tls.key
2022-10-05T19:50:32.288759Z    info    x509 cert - Issuer: "CN=cluster1.solo.io", Subject: "", SN: 7d9a3353a9fcf01ed7e492a5ee11f9ef, NotBefore: "2022-10-05T19:48:32Z", NotAfter: "2032-10-02T19:50:32Z"
2022-10-05T19:50:32.288773Z    info    x509 cert - Issuer: "CN=Solo.io Istio CA Issuer", Subject: "CN=cluster1.solo.io", SN: 534ef6afdefd0bda57eade9181f01ddf9cca1a82, NotBefore: "2022-10-05T19:45:03Z" NotAfter: "2022-11-04T19:45:33Z"
2022-10-05T19:50:32.288788Z    info    x509 cert - Issuer: "CN=solo.io", Subject: "CN=Solo.io Istio CA Issuer", SN: 56f87198ca42c8f622987c4336fc4103e719c122, NotBefore: "2022-10-05T19:36:53Z", NotAfter: "2027-10-04T19:37:23Z"
```

* Install an Eastwest gateway in mgmt cluster

```sh
helm upgrade --install istio-eastwestgateway-${ISTIO_REVISION} istio/gateway \
  --set revision=${ISTIO_REVISION} \
  --set global.hub=${ISTIO_IMAGE_REPO} \
  --set global.tag=${ISTIO_IMAGE_TAG} \
  --version ${ISTIO_VERSION} \
  --create-namespace \
  --namespace istio-eastwest \
  --kube-context ${MGMT} \
  --wait \
  -f- <<EOF
name: istio-eastwestgateway-${ISTIO_REVISION}
labels:
  istio: eastwestgateway
  revision: ${ISTIO_REVISION}
service:
  type: LoadBalancer
  ports:
  - name: tls
    port: 15443
    targetPort: 15443
  - name: https
    port: 16443
    targetPort: 16443
env:
  # Required for Gloo multi-cluster routing
  ISTIO_META_ROUTER_MODE: "sni-dnat"
EOF
```

* Install Gateways in cluster1

```sh
helm upgrade --install istio-ingressgateway-${ISTIO_REVISION} istio/gateway \
  --set revision=${ISTIO_REVISION} \
  --set global.hub=${ISTIO_IMAGE_REPO} \
  --set global.tag=${ISTIO_IMAGE_TAG} \
  --version ${ISTIO_VERSION} \
  --create-namespace \
  --namespace istio-ingress \
  --kube-context ${CLUSTER1} \
  --wait \
  -f- <<EOF
name: istio-ingressgateway-${ISTIO_REVISION}
labels:
  istio: ingressgateway
  revision: ${ISTIO_REVISION}
service:
  type: LoadBalancer
  ports:
  # main http ingress port
  - port: 80
    targetPort: 8080
    name: http2
  # main https ingress port
  - port: 443
    targetPort: 8443
    name: https
EOF

helm upgrade --install istio-eastwestgateway-${ISTIO_REVISION} istio/gateway \
  --set revision=${ISTIO_REVISION} \
  --set global.hub=${ISTIO_IMAGE_REPO} \
  --set global.tag=${ISTIO_IMAGE_TAG} \
  --version ${ISTIO_VERSION} \
  --create-namespace \
  --namespace istio-eastwest \
  --kube-context ${CLUSTER1} \
  --wait \
  -f- <<EOF
name: istio-eastwestgateway-${ISTIO_REVISION}
labels:
  istio: eastwestgateway
  revision: ${ISTIO_REVISION}
service:
  type: LoadBalancer
  ports:
  - name: tls
    port: 15443
    targetPort: 15443
env:
  # Required for Gloo multi-cluster routing
  ISTIO_META_ROUTER_MODE: "sni-dnat"
EOF
```

## Expose Centralized Apps via Gloo Gateway<a name="Lab-5"></a>

* Setup Gloo Workspace for managing the service mesh components

```yaml
kubectl create namespace ops-team --context ${MGMT}
kubectl --context ${MGMT} apply -f - <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: Workspace
metadata:
  name: ops-team
  namespace: gloo-mesh
spec:
  workloadClusters:
  - name: 'mgmt-cluster'
    namespaces:
    - name: gloo-mesh
    - name: ops-team
    - name: istio-eastwest
    - name: monitoring
  - name: 'cluster1'
    namespaces:
    - name: istio-ingress
    - name: gloo-mesh-addons
---
apiVersion: admin.gloo.solo.io/v2
kind: WorkspaceSettings
metadata:
  name: ops-team
  namespace: ops-team
spec:
  options:
    virtualDestClientMode:
      tlsTermination: {} # allow for routing to non mesh applications
    eastWestGateways:
    - selector:
        labels:
          istio: eastwestgateway
EOF
```

* Create a VirtualGateway to expose the Gloo Dashboard

```yaml
kubectl --context ${MGMT} apply -f - <<EOF
apiVersion: networking.gloo.solo.io/v2
kind: VirtualDestination
metadata:
  name: gloo-platform-ui
  namespace: ops-team
spec:
  hosts:
  - gloo-ui.solo.internal
  services:
  - labels:
      app: gloo-mesh-ui
  ports:
  - number: 8090
    protocol: HTTP
    targetPort:
      name: console
---
apiVersion: networking.gloo.solo.io/v2
kind: VirtualGateway
metadata:
  name: ingress-gateway
  namespace: ops-team
spec:
  workloads:
    - selector:
        labels:
          istio: ingressgateway
        cluster: cluster1
        namespace: istio-ingress
  listeners: 
    - http: {}
      port:
        number: 80
      allowedRouteTables:
        - host: '*'
          selector:
            workspace: ops-team
---
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: gloo-platform-ui
  namespace: ops-team
spec:
  hosts:
    - '*'
  virtualGateways:
    - name: ingress-gateway
      namespace: ops-team
      cluster: mgmt-cluster
  workloadSelectors: []
  http:
    - name: gloo-platform-ui
      labels:
        virtual-destination: gloo-platform-ui
      forwardTo:
        destinations:
          - ref:
              name: gloo-platform-ui
              namespace: ops-team
            kind: VIRTUAL_DESTINATION
            port:
              number: 8090
EOF
```

* Create the RouteTable

```sh

```


## Tune Components<a name="Lab-6"></a>

```sh
--reuse-values
```



## Monitoring<a name="Lab-7"></a>

* Install prometheus in the mgmt plane

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install --create-namespace prom prometheus-community/prometheus --version 15.10.3 -n monitoring --kube-context ${MGMT} -f install/prometheus/prom-values.yaml
```

* Install Grafana in the mgmt plane

```
kubectl apply -f install/grafana/grafana.yaml --context ${MGMT}
```



## TODO Secure the apps?

* Install the gloo mesh addons (rate-limiter/ext-auth-service) in the `cluster1` cluster. In this workshop we will use them to secure the shared services on this cluster such as the Gloo Platform UI and Grafana. 

```sh
helm upgrade --install gloo-mesh-addons gloo-mesh-agent/gloo-mesh-agent \
  --kube-context=${CLUSTER1} \
  --create-namespace \
  --namespace gloo-mesh-addons \
  --set glooMeshAgent.enabled=false \
  --set rate-limiter.enabled=true \
  --set ext-auth-service.enabled=true \
  --version ${GLOO_PLATFORM_VERSION} \
  --wait
```