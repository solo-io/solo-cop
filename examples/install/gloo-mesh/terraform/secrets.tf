# mgmt Plane
resource "kubernetes_secret" "relay_root_tls_secret_mgmt" {
  
  depends_on = [
    kubernetes_namespace.gloo_mesh_mgmt,
  ]

  provider = kubernetes.mgmt

  metadata {
    name = "relay-root-tls-secret"
    namespace = "gloo-mesh"
  }

  data = {
    "ca.crt" = "${file("${path.module}/secrets/relay-root-ca.crt")}"
    "tls.key" = "${file("${path.module}/secrets/relay-root-ca.key")}"
  }


  type = "Opaque"
}


# Cluster 1
resource "kubernetes_secret" "relay_root_tls_secret_cluster1" {
  
  depends_on = [
    kubernetes_namespace.gloo_mesh_cluster1,
  ]
  
  provider = kubernetes.cluster1

  metadata {
    name = "relay-root-tls-secret"
    namespace = "gloo-mesh"
  }

  data = {
    "ca.crt" = "${file("${path.module}/secrets/relay-root-ca.crt")}"
    "tls.key" = "${file("${path.module}/secrets/relay-root-ca.key")}"
  }


  type = "Opaque"
}

# Cluster 2
resource "kubernetes_secret" "relay_root_tls_secret_cluster2" {
  
  depends_on = [
    kubernetes_namespace.gloo_mesh_cluster2,
  ]
  
  provider = kubernetes.cluster2

  metadata {
    name = "relay-root-tls-secret"
    namespace = "gloo-mesh"
  }

  data = {
    "ca.crt" = "${file("${path.module}/secrets/relay-root-ca.crt")}"
    "tls.key" = "${file("${path.module}/secrets/relay-root-ca.key")}"
  }


  type = "Opaque"
}

#########################################################
## Relay Signing Cert and Gloo Mesh Mgmt server cert
#########################################################

# mgmt Plane
resource "kubernetes_secret" "relay_root_tls_signing_secret_mgmt" {
  
  depends_on = [
    kubernetes_namespace.gloo_mesh_mgmt,
  ]
  
  provider = kubernetes.mgmt

  metadata {
    name = "relay-tls-signing-secret"
    namespace = "gloo-mesh"
  }

  data = {
    "ca.crt" = "${file("${path.module}/secrets/relay-root-ca.crt")}"
    "tls.crt" = "${file("${path.module}/secrets/relay-signing-cert.crt")}"
    "tls.key" = "${file("${path.module}/secrets/relay-signing-cert.key")}"
  }


  type = "Opaque"
}

resource "kubernetes_secret" "relay_server_tls_mgmt" {
  
  depends_on = [
    kubernetes_namespace.gloo_mesh_mgmt,
  ]
  
  provider = kubernetes.mgmt

  metadata {
    name = "relay-server-tls-secret"
    namespace = "gloo-mesh"
  }

  data = {
    "ca.crt" = "${file("${path.module}/secrets/relay-root-ca.crt")}"
    "tls.crt" = "${file("${path.module}/secrets/gloo-mesh-mgmt-server.crt")}"
    "tls.key" = "${file("${path.module}/secrets/gloo-mesh-mgmt-server.key")}"
  }


  type = "Opaque"
}

#########################################################
## Token
#########################################################

# mgmt Plane
resource "kubernetes_secret" "relay_identity_token_secret_mgmt" {
  
  depends_on = [
    kubernetes_namespace.gloo_mesh_mgmt,
  ]
  
  provider = kubernetes.mgmt

  metadata {
    name = "relay-identity-token-secret"
    namespace = "gloo-mesh"
  }

  data = {
    "token" = var.relay_agent_token
  }

  type = "Opaque"
}


# Cluster 1
resource "kubernetes_secret" "relay_identity_token_secret_cluster1" {
  
  depends_on = [
    kubernetes_namespace.gloo_mesh_cluster1,
  ]
  
  provider = kubernetes.cluster1

  metadata {
    name = "relay-identity-token-secret"
    namespace = "gloo-mesh"
  }

  data = {
    "token" = var.relay_agent_token
  }

  type = "Opaque"
}

# Cluster 2
resource "kubernetes_secret" "relay_identity_token_secret_cluster2" {
  
  depends_on = [
    kubernetes_namespace.gloo_mesh_cluster2,
  ]

  provider = kubernetes.cluster2

  metadata {
    name = "relay-identity-token-secret"
    namespace = "gloo-mesh"
  }

  data = {
    "token" = var.relay_agent_token
  }

  type = "Opaque"
}
