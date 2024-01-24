variable "kubeconfig" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "k3s_config" {
  description = "Object containing k3s configuration"
  type = object({
    cluster_name = string
    local_domain = string
    context      = string
    nodes = map(object({
      ip   = string
      type = string
    }))
    users = map(object({
      username = string
      password = string
    }))
  })
}

variable "metallb_address_pool" {
  description = "Defines the MetalLB address pool, a map of name and addresses (ip ranges or ip/mask)"
  type = object({
    name      = string
    addresses = list(string)
  })
}

variable "google_dynamic_dns_fqdn" {
  description = "The FQDN of the dynamic DNS record to update"
  type        = string
}

variable "google_dynamic_dns_username" {
  description = "The username to use for dynamic DNS updates"
  type        = string
}

variable "google_dynamic_dns_password" {
  description = "The password to use for dynamic DNS updates"
  type        = string
}

variable "vaultwarden_config" {
  description = "Object containing vaultwarden configuration"
  type = object({
    timezone             = string
    default_vault_domain = string
    ingress_hosts        = list(string)
    allow_signups        = bool
    domain_white_list    = list(string)
    org_creation_users   = list(string)
  })
}

variable "default_smtp_config" {
  description = "Object containing default SMTP configuration"
  type = object({
    server = object({
      host      = string
      port      = string
      security  = string
      timeout   = string
      helo_name = string
    })
    auth = object({
      username = string
      password = string
    })
    email_config = object({
      from         = string
      from_name    = string
      embed_images = bool
    })
  })
  validation {
    condition     = contains(["starttls", "force_tls", "off"], var.default_smtp_config.server.security)
    error_message = "default_smtp_config.server.security must be one of: starttls, force_tls, off"
  }
  validation {
    condition     = tonumber(var.default_smtp_config.server.timeout) > 0
    error_message = "default_smtp_config.server.timeout must be greater than 0"
  }
  validation {
    condition     = (var.default_smtp_config.server.port == "465" && var.default_smtp_config.server.security == "force_tls") || (contains(["587", "25"], var.default_smtp_config.server.port) && var.default_smtp_config.server.security == "starttls") || var.default_smtp_config.server.port == "25" && var.default_smtp_config.server.security == "off"
    error_message = "default_smtp_config.server.port and default_smtp_config.server.security are incompatible. See https://github.com/dani-garcia/vaultwarden/blob/9e5b049dca6438cf289619c325406d420ef97c78/.env.template#L391"
  }
}

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

variable "postgresql_config" {
  description = "values to pass to the postgresql chart"
  type = object({
    enabled = bool
    auth = object({
      postgresPassword = string
    })
  })
  default = {
    enabled = false
    auth = {
      postgresPassword = ""
    }
  }
}

variable "cifs_backup_user" {
  description = "value of the cifs backup user"
  default     = "backup"
}

variable "cifs_backup_password" {
  description = "value of the cifs backup password"
  default     = "backup"
}

variable "cifs_backup_target" {
  description = "value of the cifs backup server"
}

variable "adguard_config" {
  description = "Object containing adguard configuration"
  type = object({
    enabled = bool
    ip      = string
    admin = object({
      token = string
    })
    api = object({
      password = string
    })
    filter_list = list(object({
      name    = string
      url     = string
      enabled = bool
    }))
    rewrites = list(object({
      hostname = string
      ip       = string
      enabled  = bool
    }))
    user_rules = list(string)
  })
  default = {
    enabled = false
    ip      = ""
    admin = {
      token = ""
    }
    api = {
      password = ""
    }
    filter_list = []
    rewrites    = []
    user_rules  = []
  }
}
