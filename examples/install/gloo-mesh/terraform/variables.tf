variable "create_gloo_mesh_namespace" {
   type = bool
   default = true
}

variable "gloo_mesh_version" {
  default = "v2.0.0-beta33"
}

variable "gloo_mesh_enterprise_helm_chart_name" {
  default = "gloo-mesh-enterprise"
}
variable "gloo_mesh_agent_helm_chart_name" {
  default = "gloo-mesh-agent"
}
variable "gloo_mesh_enterprise_helm_repo_url" {
  default = "https://storage.googleapis.com/gloo-mesh-enterprise/gloo-mesh-enterprise"
}

variable "gloo_mesh_agent_helm_repo_url" {
  default = "https://storage.googleapis.com/gloo-mesh-enterprise/gloo-mesh-agent"
}

variable "relay_agent_token" {
  default = "my-secret-token"
}

# export TF_VAR_GLOO_MESH_LICENSE_KEY=$GLOO_MESH_LICENSE_KEY
# Loaded from environment Variable TF_VAR_GLOO_MESH_LICENSE_KEY
variable "GLOO_MESH_LICENSE_KEY" {
    type        = string
}