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
  default     = "firefly"
}

variable "mysql_user" {
  description = "MySQL user name"
  type        = string
  default     = "firefly"
}

variable "mysql_storage_size" {
  description = "Storage size for MySQL"
  type        = string
  default     = "10Gi"
}

variable "mysql_cpu_limit" {
  description = "CPU limit for MySQL"
  type        = string
  default     = "1000m"
}

variable "mysql_memory_limit" {
  description = "Memory limit for MySQL"
  type        = string
  default     = "1Gi"
}

variable "mysql_cpu_request" {
  description = "CPU request for MySQL"
  type        = string
  default     = "500m"
}

variable "mysql_memory_request" {
  description = "Memory request for MySQL"
  type        = string
  default     = "512Mi"
}
