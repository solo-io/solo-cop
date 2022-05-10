resource "kubernetes_namespace" "gloo-mesh" {
  count = var.create_gloo_mesh_ns ? 1 : 0
  metadata {
    annotations = {
      name = "gloo-mesh"
    }

    name = "gloo-mesh"
  }
}

resource "helm_release" "gloo-control-plane" {
  depends_on = [
    kubernetes_secret.relay-identity-token-secret-flexport,
    kubernetes_namespace.gloo-mesh,
    kubernetes_secret.gloo-mesh-ca
  ]
  chart            = var.helm_chart_name
  namespace        = var.k8s_namespace
  create_namespace = var.create_namespace
  name             = var.helm_release_name
  version          = var.helm_chart_version
  repository       = var.helm_repo_url == "./helm" ? "${path.module}/helm" : var.helm_repo_url
  force_update     = var.force_update
  recreate_pods    = var.recreate_pods

  values = [
    yamlencode({
      cluster = var.cluster_name
      rate-limiter = {
        enabled = false
      }
      ext-auth-service = {
        enabled = false
      }
      relay = {
        serverAddress = var.gloo_mesh_relay_address
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
          name      = "relay-identity-token-secret-flexport"
          namespace = "gloo-mesh"
        }
      }
    })
  ]

  dynamic "set" {
    for_each = var.settings
    content {
      name  = set.key
      value = set.value
    }
  }
}

data "aws_secretsmanager_secret_version" "gloo_mesh_token" {
  secret_id = var.gloo_mesh_token_secret
}

resource "kubernetes_secret" "relay-identity-token-secret-flexport" {
  metadata {
    name      = "relay-identity-token-secret-flexport"
    namespace = "gloo-mesh"
  }

  data = {
    "token" = data.aws_secretsmanager_secret_version.gloo_mesh_token.secret_string
  }
}

data "aws_secretsmanager_secret_version" "root_ca_cert" {
  secret_id = var.root_ca_cert
}

data "aws_secretsmanager_secret_version" "root_ca_tls_key" {
  secret_id = var.root_ca_tls_key
}

resource "kubernetes_secret" "gloo-mesh-ca" {
  metadata {
    name      = "relay-root-tls-secret"
    namespace = "gloo-mesh"
  }

  data = {
    "ca.crt"  = data.aws_secretsmanager_secret_version.root_ca_cert.secret_string
    "tls.key" = data.aws_secretsmanager_secret_version.root_ca_tls_key.secret_string
  }
}