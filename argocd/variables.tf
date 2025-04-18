variable "argocd_namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_ip_address" {
  description = "IP address for the ArgoCD service"
  type        = string
  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.argocd_ip_address))
    error_message = "Invalid IP address"
  }
}

variable "storage_class_name" {
  description = "Storage class name for persistent volumes"
  type        = string
  default     = "longhorn-ssd"
}

variable "argocd_chart_version" {
  description = "Helm chart version for ArgoCD"
  type        = string
  default     = "5.46.7" # Latest stable version at the time of creation
}

variable "argocd_server_port" {
  description = "Port for ArgoCD server service"
  type        = number
  default     = 80
}

variable "argocd_repo_server_port" {
  description = "Port for ArgoCD repo server service"
  type        = number
  default     = 8081
}

variable "argocd_resources_limits_cpu" {
  description = "CPU limits for ArgoCD server"
  type        = string
  default     = "1"
}

variable "argocd_resources_limits_memory" {
  description = "Memory limits for ArgoCD server"
  type        = string
  default     = "1Gi"
}

variable "argocd_resources_requests_cpu" {
  description = "CPU requests for ArgoCD server"
  type        = string
  default     = "250m"
}

variable "argocd_resources_requests_memory" {
  description = "Memory requests for ArgoCD server"
  type        = string
  default     = "256Mi"
}

variable "argocd_admin_password" {
  description = "Admin password for ArgoCD (will be bcrypt hashed)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "argocd_insecure" {
  description = "Disable TLS on the ArgoCD API server"
  type        = bool
  default     = false
}

variable "argocd_ha_enabled" {
  description = "Enable high availability mode for ArgoCD"
  type        = bool
  default     = false
}

variable "argocd_server_replicas" {
  description = "Number of ArgoCD server replicas"
  type        = number
  default     = 1
}

variable "argocd_repo_server_replicas" {
  description = "Number of ArgoCD repo server replicas"
  type        = number
  default     = 1
}

variable "argocd_application_controller_replicas" {
  description = "Number of ArgoCD application controller replicas"
  type        = number
  default     = 1
}

variable "argocd_dex_enabled" {
  description = "Enable Dex for SSO integration"
  type        = bool
  default     = false
}

variable "argocd_repositories" {
  description = "Git repositories to configure in ArgoCD"
  type = list(object({
    name     = string
    url      = string
    username = optional(string)
    password = optional(string)
    ssh_key  = optional(string)
  }))
  default = []
}

variable "argocd_projects" {
  description = "ArgoCD projects to create"
  type = list(object({
    name         = string
    description  = optional(string)
    source_repos = optional(list(string), ["*"])
    destinations = optional(list(object({
      server    = string
      namespace = string
    })), [{ server = "https://kubernetes.default.svc", namespace = "*" }])
  }))
  default = []
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}
