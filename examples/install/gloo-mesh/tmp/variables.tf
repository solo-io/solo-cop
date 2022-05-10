# Helm

variable "helm_chart_name" {
  type        = string
  default     = "gloo-mesh-agent"
  description = "Helm chart name to be installed"
}

variable "helm_chart_version" {
  type        = string
  default     = "v2.0.0-beta33"
  description = "Version of the Helm chart"
}

variable "helm_release_name" {
  type        = string
  default     = "gloo-mesh-agent"
  description = "Helm release name"
}

variable "helm_repo_url" {
  type        = string
  default     = "https://storage.googleapis.com/gloo-mesh-enterprise/gloo-mesh-agent"
  description = "Helm repository"
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "Have helm_resource create the namespace, default true"
}

variable "force_update" {
  type        = bool
  default     = false
  description = "(Optional) Force resource update through delete/recreate if needed. Defaults to false"
}

variable "recreate_pods" {
  type        = bool
  default     = false
  description = "(Optional) Perform pods restart during upgrade/rollback. Defaults to false."
}

# K8s

variable "k8s_namespace" {
  type        = string
  default     = "gloo-mesh"
  description = "The K8s namespace in which to install the Helm chart, default: 'gloo-mesh'"
}

variable "settings" {
  type        = map(any)
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values, see https://hub.helm.sh/charts/stable/cluster-autoscaler"
}

variable "cluster_name" {
  description = "Name of fke cluster"
}

variable "gloo_mesh_token_secret" {
  type        = string
  description = "The AWS secret arn for gloo mesh token"
  default     = "REDACTED"
}

variable "root_ca_cert" {
  type        = string
  description = "AWS secret holding CA cert used for Gloo Mesh Ent mesh"
  default     = "REDACTED"
}

variable "root_ca_tls_key" {
  type        = string
  description = "AWS secret holding CA key used for Gloo Mesh Ent mesh"
  default     = "ARN_REDACTED"
}

variable "create_gloo_mesh_ns" {
  type        = bool
  description = "To creation gloo-mesh ns or not"
  default     = true
}

variable "gloo_mesh_relay_address" {
  type        = string
  description = "The Gloo Mesh management plane relay NLB endpoint"
}