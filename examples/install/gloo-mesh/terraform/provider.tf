terraform {

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "mgmt"
  alias = "mgmt"
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "cluster1"
  alias = "cluster1"
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "cluster2"
  alias = "cluster2"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    config_context = "mgmt"
  }
  alias = "mgmt"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    config_context = "cluster1"
  }
  alias = "cluster1"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    config_context = "cluster2"
  }
  alias = "cluster2"
}

provider "kubectl" {
  config_path    = "~/.kube/config"
  config_context = "mgmt"
}