variable "flowise_config" {
  description = "Object containing flowise configuration"
  type = object({
    enabled = bool
    auth = object({
      username   = string
      password   = string
      passphrase = string
    })
    ingress = object({
      enabled = bool
      hosts = object({
        internal_hostname = string
        external_hostname = string
      })
    })
    database = object({
      enabled  = bool
      port     = number
      username = string
      password = string
      database = string
    })
  })
  default = {
    enabled = false
    auth = {
      username   = "admin"
      password   = ""
      passphrase = ""
    }
    ingress = {
      enabled = true
      hosts = {
        internal_hostname = ""
        external_hostname = ""
      }
    }
    database = {
      enabled  = false
      port     = 5432
      database = "flowise"
      username = ""
      password = ""
    }
  }
  validation {
    condition     = length(keys(var.flowise_config)) > 0
    error_message = "At least one configuration option must be set"
  }

  validation {
    condition     = var.flowise_config.auth.username != null && var.flowise_config.auth.password != null
    error_message = "Both username and password must be set"
  }
  validation {
    condition     = var.flowise_config.auth.passphrase != null
    error_message = "Passphrase must be set"
  }
  validation {
    condition     = var.flowise_config.database.port > 2000 && var.flowise_config.database.port < 65536
    error_message = "Database port must be between 2000 and 65535"
  }
  validation {
    condition     = var.flowise_config.database.database != "postgres"
    error_message = "Database name cannot be 'postgres'"
  }
  validation {
    condition     = var.flowise_config.database.username != "postgres"
    error_message = "Database username cannot be 'postgres'"
  }
  validation {
    condition     = var.flowise_config.database.password != "postgres"
    error_message = "Database password cannot be 'postgres'"
  }
}

variable "postgresql_cluster_host" {
  type = string
}
