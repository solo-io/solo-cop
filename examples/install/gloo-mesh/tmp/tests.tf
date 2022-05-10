// Example tests here
// Apply your module more than once to ensure it is reusable without collision of resources names
// Apply it with different variable inputs and usage patterns where possible to test
//

variable "merge_request_id" {
  type        = string
  description = "The merge request ID, should be passed from CD pipeline as TF_VAR_merge_request_id, fp-breakbulk will set., Required for tes  ting MR infra"
}

locals {
  cluster_name = format("%s-test-mr-%s", "gloo-control-plane", var.merge_request_id)
}

data "aws_eks_cluster" "cluster" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    token                  = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  }
}

data "aws_eks_cluster_auth" "gloo_mesh_management_cluster" {
  name = "gloo-management-plane-test-mr-2"
}

data "aws_eks_cluster" "gloo_mesh_management_cluster" {
  name = "gloo-management-plane-test-mr-2"
}

// Gloo Mesh Management Plane EKS setup
provider "aws" {
  region = "us-east-1"
}

provider "kubernetes" {
  alias                  = "gloo-mesh"
  host                   = data.aws_eks_cluster.gloo_mesh_management_cluster.endpoint
  token                  = data.aws_eks_cluster_auth.gloo_mesh_management_cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.gloo_mesh_management_cluster.certificate_authority.0.data)
}

resource "kubernetes_manifest" "kubernetescluster_gloo_mesh_remote_cluster_test" {
  provider = kubernetes.gloo-mesh
  manifest = {
    "apiVersion" = "admin.gloo.solo.io/v2"
    "kind"       = "KubernetesCluster"
    "metadata" = {
      "name"      = local.cluster_name
      "namespace" = "gloo-mesh"
      "labels" = {
        "env" = "nonprod"
      }
    }
    "spec" = {
      "clusterDomain" = "cluster.local"
    }
  }
}

module "gloo-control-plane" {
  depends_on              = [kubernetes_manifest.kubernetescluster_gloo_mesh_remote_cluster_test]
  source                  = "../../"
  cluster_name            = local.cluster_name
  gloo_mesh_relay_address = "ELB_DNS_HERE:9900"
}