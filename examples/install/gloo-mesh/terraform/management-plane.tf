resource "helm_release" "gloo_mesh_management_plane" {
  provider = helm.mgmt
  depends_on       = [
    kubernetes_secret.relay_root_tls_secret_mgmt,
    kubernetes_secret.relay_root_tls_signing_secret_mgmt,
    kubernetes_secret.relay_identity_token_secret_mgmt, 
    kubernetes_namespace.gloo_mesh_mgmt
    ]

  chart            = var.gloo_mesh_enterprise_helm_chart_name
  namespace        = "gloo-mesh"
  create_namespace = var.create_gloo_mesh_namespace
  name             = "gloo-mesh-enterprise"
  version          = var.gloo_mesh_version
  repository       = var.gloo_mesh_enterprise_helm_repo_url == "./helm" ? "${path.module}/helm" : var.gloo_mesh_enterprise_helm_repo_url
  force_update     = true
  recreate_pods    = true
  cleanup_on_fail  = false

  values = [
    yamlencode({
      licenseKey = var.GLOO_MESH_LICENSE_KEY
      mgmtClusterName = "mgmt-cluster"

      // serviceOverrides = {
      //   metadata = {
      //     annotations = {
      //       "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
      //       "service.beta.kubernetes.io/aws-load-balancer-internal" = "true"
      //       "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
      //       "service.beta.kubernetes.io/aws-load-balancer-subnets" = "my-subnet-1,my-subnet-2"
      //     }
      //   }
      // }
      glooMeshMgmtServer = {
        // We will create our own LB in terraform
        serviceType = "ClusterIP"
        concurrency = 10
        relay = {
          // Enable relay ca signing
          disableCa = false
          // User will provide their own signing certificate
          disableCaCertGeneration = true
          // User will provide their own token
          disableTokenGeneration = true

          tlsSecret = {
            name      = "relay-server-tls-secret"
          }
          signingTlsSecret = {
            name      = "relay-tls-signing-secret"
          }
          tokenSecret = {
            name      = "relay-identity-token-secret"
            key       = "token"
          }
        }
      }
      glooMeshUi = {
        enabled = true
      // serviceOverrides = {
      //   metadata = {
      //     annotations = {
      //       "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
      //       "service.beta.kubernetes.io/aws-load-balancer-internal" = "true"
      //       "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
      //       "service.beta.kubernetes.io/aws-load-balancer-subnets" = "my-subnet-1,my-subnet-2"
      //     }
      //   }
      // }
        // auth = {
        //   enabled = false
        //   backend = ""
        //   oidc = {
        //     appUrl = ""
        //     clientId = ""
        //     clientSecret = ""
        //     clientSecretName = ""
        //     issuerUrl = ""
        //     session = {
        //       backend = ""
        //       redis= {
        //         host = ""
        //       }
        //     }      
        //   }
        // }
      }
      prometheus = {
        enabled = true
      }
      glooMeshRedis = {
        enabled = true
      }
    })
  ]
}

resource "kubernetes_service" "gloo_mesh_mgmt_server" {
  provider = kubernetes.mgmt
  metadata {
    name = "gloo-mesh-external"
    namespace = "gloo-mesh"
  }
  spec {
    port {
      port        = 9900
      target_port = 9900
    }
    type = "LoadBalancer"
    selector = {
      app = "gloo-mesh-mgmt-server"
    }
  }
}

locals {
  gloo_mesh_relay_address = "${kubernetes_service.gloo_mesh_mgmt_server.status.0.load_balancer.0.ingress.0.ip}:9900"
}


resource "kubectl_manifest" "gloo_mesh_kubernetesclusters_cluster1" {
  depends_on = [
    helm_release.gloo_mesh_management_plane
  ]
  yaml_body = <<YAML
apiVersion: admin.gloo.solo.io/v2
kind: KubernetesCluster
metadata:
  name: cluster1
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
YAML
}

resource "kubectl_manifest" "gloo_mesh_kubernetescluster_cluster2" {
  depends_on = [
    helm_release.gloo_mesh_management_plane
  ]
  yaml_body = <<YAML
apiVersion: admin.gloo.solo.io/v2
kind: KubernetesCluster
metadata:
  name: cluster2
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
YAML
}