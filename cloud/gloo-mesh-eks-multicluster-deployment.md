WIP...

# Gloo Mesh Multi-Cluster EKS Deployment

This guide defines best practices for deploying  multi-cluster gloo mesh in eks environment.

## 0. Architecture diagram

![](images/gloo-mesh-eks-multicluster-architecture.png)

## 1. Pre-requisistes

The following pre-requisistes are expected to be in place:
* EKS cluster to host gloo mesh management plane. management cluster. The architecture diagram shows a high-available management cluster over 3 availability zones.
* EKS clusters hosting your applications to join the multicluster gloo-mesh setup as worker cluster (managed by the centralized gloo management). The architecture diagram show high-available worker clusters across 3 availability zones.
* [AWS Load-Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html) and [Amazon EBS CSI Driver](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html) deployed with service accounts attached to iam policy to be able to provision cloud load-balancers and storage
* Inter-VPC mesh connectivity implemented using aws vpc connectivity [options](https://docs.aws.amazon.com/whitepapers/latest/aws-vpc-connectivity-options/introduction.html)
* Connectivity from your management network to the management cluster using one of aws vpc connectivity [options](https://docs.aws.amazon.com/whitepapers/latest/aws-vpc-connectivity-options/network-to-amazon-vpc-connectivity-options.html)
* AWS security groups allowing required communication for [istio](https://istio.io/latest/docs/ops/deployment/requirements/) and [gloo mesh](https://docs.solo.io/gloo-mesh-enterprise/latest/concepts/about/)
* Kubernetes network policies allowing required communication
* RBAC and Admission Controller privileges allowing the deployment of privileged pods.

## 2. Istio Installation

Gloo-mesh requires istio to be installed in clusters so that it can manage its configuration. Gloo mesh v1.3.0 introduced support for istio installation lifecycle management (experimental until declared GA).

The following recommendations apply to the istio installation:
* It is recommended to install istio in all clusters including the management cluster. It is expected that the same management cluster would be hosting the management plane of other platform application and this provides the capability of securing and segmenting the management and control plane in addition to the dataplane.
* Install istio in your management and workload clusters using the following guidelines:
    * [Link](https://istio.io/latest/docs/setup/platform-setup/) to istio documentation for deployment guidelines
    * [Link](https://docs.solo.io/gloo-mesh-enterprise/latest/setup/istio/istio_production/) to gloo mesh documentation for best-practices for using istio in production
* It is recommended to deploy separate istio ingress gateways for east-west (inter-vpc communication) and north-south (communication with the outside world for exposing services or management). [Link](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/guide/service/nlb/) to aws load-balancer controller annotation guidelines.
  * Following are required service annotations for setting up the NLB fot the east-west ingress gateway service
```
  annotations:
    # Enables load-balancing across availability zones
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    # Instructs NLB to send traffic to the EC2 instances and the kube-proxy on the individual worker nodes forward it to the pods through one or more worker nodes in the Kubernetes cluster.
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
    # Instructs NLB to create an internal load-balancer
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
    # Ignore in-tree controllers and pass it to aws cloud load-balancer controller
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    # Define healthcheck probes from NLB to istio ingress-gateway
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: "/healthz/ready"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-port: "15021"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol: "http"
```
  * Label your east-west ingress gateway.
```
  labels:
    ingressgateway.istio/type: internal
    ingressgateway.istio/direction: east-west
```
  * Following are required service annotations for setting up the NLB fot the north-south ingress gateway service
```
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "external"
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-healthy-threshold: "2"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-unhealthy-threshold: "2"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval: "10"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: "/healthz/ready"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-port: "15021"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol: "http"
```
  * Label your north-south ingress gateways. The management cluster north-south gateway is expected to be an internal load-balancing connecting to your enterprise network. The worker clusters north-south gateways are expected to be external for exposing your applications.
    * Label management cluster north-south gateway.
```
  labels:
    ingressgateway.istio/type: internal
    ingressgateway.istio/direction: north-south
```
    * Label worker clusters north-south gateways.
```
  labels:
    ingressgateway.istio/type: external
    ingressgateway.istio/direction: north-south
```

## 3. Gloo Mesh Installation

* Install gloo mesh enterprise in management cluster. 
  * [Link](https://docs.solo.io/gloo-mesh-enterprise/latest/setup/installation/enterprise_installation/) to gloo mesh documentation for gloo mesh installation guidelines
  * [Link](https://docs.solo.io/gloo-mesh-enterprise/latest/reference/helm/gloo_mesh_enterprise/) to gloom mesh helm values reference
* Register the local management cluster for management by gloo mesh enterprise. 
  * [Guidelines](https://docs.solo.io/gloo-mesh-enterprise/latest/setup/cluster_registration/enterprise_cluster_registration/) for registering clusters with gloo mesh
  * Use local enterprise networking service address as relay address, for example: enterprise-networking.your-cluster-domain:9900
* Expose Enterprise Networking Service via the East-West Istio Ingress Gateway for connectivity from remote clusters.
  * It is advisable to use a controller for managing route53 dns record of gateway services, such as [External DNS](https://github.com/kubernetes-sigs/external-dns)
  * Add the following annotation to east-west istio ingress gateway service to instruct external dns to update route53 A records
```
  annotations:
    external-dns.alpha.kubernetes.io/hostname: relay-jad-mgmt.your-domain
```
  * Gloo mesh enterprise installation deploys Enterprise Networking services which is listening for connections from remote clusters for management. Expose the Enterprise Networking Service via the east-west gateway.
```
apiVersion: networking.enterprise.mesh.gloo.solo.io/v1beta1
kind: enterprise-networking
metadata:
  name: istio-ingressgateway-east-west
  namespace: gloo-mesh
spec:
  connectionHandlers:
  - connectionOptions:
      sslConfig:
        tlsMode: PASSTHROUGH
    connectionMatch: 
      serverNames:
      - relay.your-domain:9900
    http:
      routeConfig:
      - virtualHostSelector:
          namespaces:
          - "gloo-mesh"
  ingressGatewaySelectors:
  - destinationSelectors:
    - kubeServiceMatcher:
        clusters:
        - your-management-cluster-name
        labels:
          istio: ingressgateway
          ingressgateway.istio/type: internal
          ingressgateway.istio/direction: east-west
        namespaces:
        - istio-system
    portName: https
---
apiVersion: networking.enterprise.mesh.gloo.solo.io/v1beta1
kind: VirtualHost
metadata:
  name: enterprise-networking
  namespace: gloo-mesh
spec:
  domains:
  - "relay.your-domain:9900"
  routes:
  - matchers:
    - uri:
        prefix: /
    name: ratings
    routeAction:
      destinations:
      - kubeService:
          clusterName: your-management-cluster-name
          name: enterprise-networking
          namespace: gloo-mesh
```
* Register remote clusters with gloo mesh.
  * [Guide](https://docs.solo.io/gloo-mesh-enterprise/latest/setup/cluster_registration/enterprise_cluster_registration/) for registering worker clusters with gloo mesh

