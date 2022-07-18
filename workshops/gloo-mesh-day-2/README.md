![Gloo Enterprise](images/gloo-mesh-2.0-banner.png)

# <center>Gloo Day 2 Workshop</center>

## Table of Contents

* [Introduction](#introduction)
* [Lab 1 - Deploy Kubernetes clusters](#Lab-1)
* [Lab 2 - PKI / Vault and Cert Manager](#Lab-2)
* [Lab 3 - Install Gloo Mesh](#Lab-3)
* [Lab 4 - Install Istio](#Lab-4)
* [Lab 5 - Tune Gloo Management Server](#Lab-5)
* [Lab 6 - Monitoring](#Lab-6)
* [Lab 7 - Expose Centralized Apps via Gloo Gateway](#Lab-7)

## Introduction <a name="introduction"></a>

![Day 2 Workshop Architecture](images/day2-arch.png)

The day 2 Gloo workshop is all about the best practices and architectures to make your mutli-cluster deployment resilient, secure, and maintainable for the long term. This workshop was created based upon how Solo.io customers have been able to successfully run Gloo in Production as well as the knowledge from our Istio experts. 

High level best practices:
* Use helm and GitOps for deploying infrastructure to kubernetes
* Monitor and create alerts for your operational infrastructure
* Keep your PKI secure and rotate certificates
* Scale your components for resiliency


### Want to learn more about Gloo?

You can find more information about Gloo in the official documentation:

[https://docs.solo.io/gloo-mesh/latest/](https://docs.solo.io/gloo-mesh/latest/)

## Begin

To get started with this workshop, clone this repo.

```sh
git clone https://github.com/solo-io/solo-cop.git
cd solo-cop/workshops/gloo-mesh-demo && git checkout v1.1.0
```

Set these environment variables which will be used throughout the workshop.

```sh
# Used to enable Gloo (please ask for a trail license key)
export GLOO_LICENSE_KEY=<licence_key>
export GLOO_PLATFORM_VERSION=v2.0.11
export ISTIO_VERSION=1.14.1
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

It is important to design and implement a secure and reliable Public Key Infrastructure (PKI) that Gloo and Istio can rely on. In this workload we have chosen `Vault` and `cert-manager` as the PKI due to their versiatility and reliability for managing certificates. 

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
export VAULT_TOKEN=$(kubectl get configmap -n vault --context $MGMT cert-manager-token -o json | jq -r '.data.token')

printf "\n\nYour vault token: $VAULT_TOKEN\n"
```

### Cert Manager

This workshop chose cert manager as the last-mile certificate management solution for a number of reasons. First, it is the most widely used Kubernetes based solution. Secondly, it natively integrates with a number of different issuing systems such as [AWS Private CA](https://github.com/cert-manager/aws-privateca-issuer), [Google Cloud CA](https://github.com/jetstack/google-cas-issuer) and [Vault](https://cert-manager.io/docs/configuration/vault/). Finally, cert-manager also creates certificates in the form of kubernetes secrets which are compatible with both Istio and Gloo Platform. It also has the ability to automatically rotate them when they are nearing their end of life.

![Cert Manager Backends](./images/cert-manager-pki.png)

* Deploy cert-manager to both the `mgmt` and `cluster1` clusters

```sh
kubectl --context ${MGMT} apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml
kubectl --context ${CLUSTER1} apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml

kubectl wait deployment --for condition=Available=True -n cert-manager --context $MGMT --all
kubectl wait deployment --for condition=Available=True -n cert-manager --context $CLUSTER1 --all
```

* Create the kubernetes secret containing the Vault token in each `cert-manager` namespace. This will be used by cert-manager to authenticate with Vault

```sh
kubectl create secret generic vault-token -n cert-manager --context $MGMT --from-literal=token=$VAULT_TOKEN
kubectl create secret generic vault-token -n cert-manager --context $CLUSTER1 --from-literal=token=$VAULT_TOKEN
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
    auth:
      tokenSecretRef:
        name: vault-token
        key: token
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
    auth:
      tokenSecretRef:
        name: vault-token
        key: token
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
    auth:
      tokenSecretRef:
        name: vault-token
        key: token
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
    auth:
      tokenSecretRef:
        name: vault-token
        key: token
EOF
```

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
  duration: 1h
  renewBefore: 30m
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
  duration: 1h
  renewBefore: 30m
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
kubectl --context $MGMT_CONTEXT apply -f - <<EOF
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
  issuerRef:
    kind: ClusterIssuer
    name: vault-issuer-gloo
  renewBefore: 8736h0m0s
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
  issuerRef:
    kind: ClusterIssuer
    name: vault-issuer-gloo
  renewBefore: 8736h0m0s
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
  issuerRef:
    kind: ClusterIssuer
    name: vault-issuer-gloo
  renewBefore: 8736h0m0s
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
kubectl get secret gloo-server-tls-secret -n gloo-mesh --context $MGMT
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

### Install Gloo

* Install the management plane via helm

```sh
helm upgrade --install gloo-mesh-enterprise gloo-mesh-enterprise/gloo-mesh-enterprise \
  --version=${GLOO_PLATFORM_VERSION} \
  --set licenseKey=${GLOO_MESH_LICENSE_KEY} \
  --kube-context ${MGMT} \
  --namespace gloo-mesh \
  --set glooMeshMgmtServer.relay.disableTokenGeneration=true \
  --set glooMeshMgmtServer.relay.disableCa=true \
  --set glooMeshMgmtServer.relay.disableCaCertGeneration=true \
  --set glooMeshMgmtServer.relay.tlsSecret.name=gloo-server-tls-cert \
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
helm upgrade --install gloo-mesh-agent gloo-mesh-agent/gloo-mesh-agent \
--kube-context=${CLUSTER1} \
--namespace gloo-mesh \
--set relay.serverAddress=${RELAY_ADDRESS} \
--set cluster=${CLUSTER1} \
--set relay.clientTlsSecret.name=gloo-mesh-agent-tls-cert \
--version ${GLOO_PLATFORM_VERSION} \
--wait
```

## Install Istio <a name="Lab-4"></a>

```sh
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
```

* Install Istio CRDs

```sh
helm upgrade --install istio-base istio/base \
  -n istio-system \
  --version $ISTIO_VERSION \
  --kube-context $MGMT \
  --create-namespace

helm upgrade --install istio-base istio/base \
  -n istio-system \
  --version $ISTIO_VERSION \
  --kube-context $CLUSTER1\
  --create-namespace
```

* Install Istio control plane

```sh
helm upgrade --install istiod istio/istiod \
  -f install/istio/operator-mgmt.yaml \
  --namespace istio-system \
  --version $ISTIO_VERSION \
  --kube-context $MGMT \
  --wait

helm upgrade --install istiod istio/istiod \
  -f install/istio/operator-cluster1.yaml \
  --namespace istio-system \
  --version $ISTIO_VERSION \
  --kube-context $CLUSTER1 \
  --wait
```

* Install Gateways in mgmt cluster

```sh
helm upgrade --install istio-ingressgateway istio/gateway \
  -f install/istio/ingress-gateway-mgmt.yaml \
  --create-namespace \
  --namespace istio-gateways \
  --version $ISTIO_VERSION \
  --kube-context $MGMT \
  --wait


helm upgrade --install istio-eastwestgateway istio/gateway \
  -f $tmp_dir/eastwest-gateway-mgmt.yaml \
  --create-namespace \
  --namespace istio-gateways \
  --version $ISTIO_VERSION \
  --kube-context $MGMT
```

* Install Gateways in cluster1

```sh
helm upgrade --install istio-ingressgateway istio/gateway \
  -f install/istio/ingress-gateway-cluster1.yaml \
  --create-namespace \
  --namespace istio-gateways \
  --version $ISTIO_VERSION \
  --kube-context $CLUSTER1 \
  --wait

helm upgrade --install istio-eastwestgateway istio/gateway \
  -f $tmp_dir/eastwest-gateway-cluster1.yaml \
  --create-namespace \
  --namespace istio-gateways \
  --version $ISTIO_VERSION \
  --kube-context $CLUSTER1
```

## Tune Gloo Management Server<a name="Lab-5"></a>

## Monitoring <a name="Lab-6"></a>

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

## Expose Centralized Apps via Gloo Gateway<a name="Lab-7"></a>