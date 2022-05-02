resource "kubernetes_namespace" "gloo_mesh_mgmt" {
  count = var.create_gloo_mesh_namespace ? 1 : 0
  
  provider = kubernetes.mgmt

  metadata {
    annotations = {
      name = "gloo-mesh"
    }

    name = "gloo-mesh"
  }
}

resource "kubernetes_namespace" "gloo_mesh_cluster1" {
  count = var.create_gloo_mesh_namespace ? 1 : 0
  
  provider = kubernetes.cluster1

  metadata {
    annotations = {
      name = "gloo-mesh"
    }

    name = "gloo-mesh"
  }
}

resource "kubernetes_namespace" "gloo_mesh_cluster2" {
  count = var.create_gloo_mesh_namespace ? 1 : 0
  
  provider = kubernetes.cluster2

  metadata {
    annotations = {
      name = "gloo-mesh"
    }

    name = "gloo-mesh"
  }
}