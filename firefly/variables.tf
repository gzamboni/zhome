variable "domain" {
  description = "Domain name"
  type        = string
}

variable "firefly_app_key" {
  description = "Firefly App Key for Laravel encryption (32 characters). Leave empty to auto-generate."
  type        = string
  default     = ""
  sensitive   = true
}

variable "firefly_app_password" {
  description = "Firefly App Password for initial user setup"
  type        = string
  sensitive   = true
}

variable "cpu_request" {
  type    = string
  default = "10m"
}

variable "memory_request" {
  type    = string
  default = "256Mi"
}

variable "memory_limit" {
  type    = string
  default = "512Mi"
}

variable "fqdn" {
  description = "Fully Qualified Domain Name for the Firefly III application"
  type        = string
  default     = "fin.local"
}

variable "mysql_namespace" {
  description = "Namespace where MySQL is deployed"
  type        = string
  default     = "mysql"
}

variable "mysql_service_name" {
  description = "Name of the MySQL service"
  type        = string
  default     = "mysql"
}

variable "firefly_db_name" {
  description = "Database name for Firefly III"
  type        = string
  default     = "firefly"
}

variable "firefly_db_user" {
  description = "Database user for Firefly III"
  type        = string
  default     = "firefly"
}

variable "firefly_db_password" {
  description = "Database password for Firefly III. Leave empty to auto-generate."
  type        = string
  default     = ""
  sensitive   = true
}
