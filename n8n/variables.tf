variable "n8n_namespace" {
  description = "Kubernetes namespace for n8n"
  type        = string
  default     = "n8n"
}

variable "n8n_ip_address" {
  description = "IP address for the n8n service"
  type        = string
  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.n8n_ip_address))
    error_message = "Invalid IP address"
  }
}

variable "storage_class_name" {
  description = "Storage class name for persistent volumes"
  type        = string
  default     = "longhorn"
}

variable "n8n_data_storage_size" {
  description = "Size of the persistent volume for n8n data"
  type        = string
  default     = "5Gi"
}

variable "n8n_image" {
  description = "Docker image for n8n"
  type        = string
  default     = "n8nio/n8n:2.0.0-rc.0"
}

variable "n8n_replicas" {
  description = "Number of n8n replicas"
  type        = number
  default     = 1
}

variable "n8n_port" {
  description = "Port for n8n service"
  type        = number
  default     = 5678
}

variable "n8n_resources_limits_cpu" {
  description = "CPU limits for n8n"
  type        = string
  default     = "1"
}

variable "n8n_resources_limits_memory" {
  description = "Memory limits for n8n"
  type        = string
  default     = "1Gi"
}

variable "n8n_resources_requests_cpu" {
  description = "CPU requests for n8n"
  type        = string
  default     = "250m"
}

variable "n8n_resources_requests_memory" {
  description = "Memory requests for n8n"
  type        = string
  default     = "256Mi"
}

variable "n8n_encryption_key" {
  description = "Encryption key for n8n"
  type        = string
  sensitive   = true
  default     = ""
}

variable "n8n_webhook_url" {
  description = "Webhook URL for n8n"
  type        = string
  default     = ""
}

variable "n8n_timezone" {
  description = "Timezone for n8n"
  type        = string
  default     = "UTC"
}

variable "n8n_basic_auth_user" {
  description = "Basic auth username for n8n"
  type        = string
  default     = ""
}

variable "n8n_basic_auth_password" {
  description = "Basic auth password for n8n"
  type        = string
  sensitive   = true
  default     = ""
}

variable "n8n_db_type" {
  description = "Database type for n8n (sqlite, postgresdb, mysqldb)"
  type        = string
  default     = "sqlite"
  validation {
    condition     = contains(["sqlite", "postgresdb", "mysqldb"], var.n8n_db_type)
    error_message = "Valid values for n8n_db_type are: sqlite, postgresdb, mysqldb"
  }
}

variable "n8n_db_host" {
  description = "Database host for n8n"
  type        = string
  default     = ""
}

variable "n8n_db_port" {
  description = "Database port for n8n"
  type        = number
  default     = 5432
}

variable "n8n_db_name" {
  description = "Database name for n8n"
  type        = string
  default     = "n8n"
}

variable "n8n_db_user" {
  description = "Database user for n8n"
  type        = string
  default     = "n8n"
}

variable "n8n_db_password" {
  description = "Database password for n8n"
  type        = string
  sensitive   = true
  default     = ""
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

