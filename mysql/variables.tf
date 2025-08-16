# General configuration
variable "name" {
  description = "Name for the MySQL deployment"
  type        = string
  default     = "mysql"
}

variable "namespace" {
  description = "Kubernetes namespace where MySQL will be deployed"
  type        = string
  default     = "mysql"
}

variable "create_namespace" {
  description = "Whether to create the namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Additional labels to add to all resources"
  type        = map(string)
  default     = {}
}

# MySQL configuration
variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  sensitive   = true
}

variable "mysql_password" {
  description = "MySQL user password"
  type        = string
  sensitive   = true
}

variable "mysql_database" {
  description = "MySQL database name"
  type        = string
  default     = "mysql"
}

variable "mysql_user" {
  description = "MySQL user name"
  type        = string
  default     = "mysql"
}

# Image configuration
variable "image_repository" {
  description = "MySQL image repository"
  type        = string
  default     = "mysql"
}

variable "image_tag" {
  description = "MySQL image tag"
  type        = string
  default     = "8.0"
}

# Storage configuration
variable "storage_size" {
  description = "Storage size for MySQL data"
  type        = string
  default     = "10Gi"
}

variable "storage_class_name" {
  description = "Storage class name for the persistent volume claim"
  type        = string
  default     = "standard"
}

# Resource configuration
variable "resources" {
  description = "Resource requests and limits for the MySQL container"
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    limits = {
      cpu    = "1000m"
      memory = "1Gi"
    }
    requests = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

# Node configuration
variable "node_selector" {
  description = "Node selector for the MySQL pod"
  type        = map(string)
  default     = {}
}

# Service configuration
variable "service_type" {
  description = "Kubernetes service type for MySQL"
  type        = string
  default     = "ClusterIP"
}

variable "external_fqdn" {
  description = "External FQDN for accessing MySQL outside the cluster"
  type        = string
  default     = ""
}

# Kubernetes provider configuration
variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Context to use from the kubeconfig file"
  type        = string
  default     = ""
}
