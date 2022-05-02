resource "helm_release" "gloo_mesh_control_plane_cluster1" {
  provider = helm.cluster1
  depends_on = [
    kubernetes_secret.relay_identity_token_secret_cluster1,
    kubernetes_namespace.gloo_mesh_cluster1,
    kubernetes_secret.relay_root_tls_secret_cluster1,
    helm_release.gloo_mesh_management_plane
  ]
  chart            = var.gloo_mesh_agent_helm_chart_name
  namespace        = "gloo-mesh"
  create_namespace = var.create_gloo_mesh_namespace
  name             = "gloo-mesh-agent"
  version          = var.gloo_mesh_version
  repository       = var.gloo_mesh_agent_helm_repo_url == "./helm" ? "${path.module}/helm" : var.gloo_mesh_agent_helm_repo_url
  force_update     = true
  recreate_pods    = true
  cleanup_on_fail  = false

  values = [
    yamlencode({
      cluster   = "cluster1"
      rate-limiter = {
        enabled = false
      }
      ext-auth-service = {
        enabled = false
      }
      relay = {
        serverAddress = local.gloo_mesh_relay_address
        clientCertSecret = {
          name      = "relay-client-tls-secret"
          namespace = "gloo-mesh"
        }
        rootTlsSecret = {
          name      = "relay-root-tls-secret"
          namespace = "gloo-mesh"
        }
        tokenSecret = {
          key       = "token"
          name      = "relay-identity-token-secret"
          namespace = "gloo-mesh"
        }
      }
    })
  ]
}

resource "helm_release" "gloo_mesh_control_plane_cluster2" {
  provider = helm.cluster2
  depends_on = [
    kubernetes_secret.relay_identity_token_secret_cluster2,
    kubernetes_namespace.gloo_mesh_cluster2,
    kubernetes_secret.relay_root_tls_secret_cluster2,
    helm_release.gloo_mesh_management_plane
  ]
  chart            = var.gloo_mesh_agent_helm_chart_name
  namespace        = "gloo-mesh"
  create_namespace = var.create_gloo_mesh_namespace
  name             = "gloo-mesh-agent"
  version          = var.gloo_mesh_version
  repository       = var.gloo_mesh_agent_helm_repo_url == "./helm" ? "${path.module}/helm" : var.gloo_mesh_agent_helm_repo_url
  force_update     = true
  recreate_pods    = true
  cleanup_on_fail  = false

  values = [
    yamlencode({
      cluster   = "cluster2"
      rate-limiter = {
        enabled = false
      }
      ext-auth-service = {
        enabled = false
      }
      relay = {
        serverAddress = local.gloo_mesh_relay_address
        clientCertSecret = {
          name      = "relay-client-tls-secret"
          namespace = "gloo-mesh"
        }
        rootTlsSecret = {
          name      = "relay-root-tls-secret"
          namespace = "gloo-mesh"
        }
        tokenSecret = {
          key       = "token"
          name      = "relay-identity-token-secret"
          namespace = "gloo-mesh"
        }
      }
    })
  ]
}
