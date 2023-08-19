variable "cluster_name" {
  description = "value of the cluster name"
  type        = string
  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]*[$]?$", var.cluster_name))
    error_message = "Invalid cluster name"
  }
}

variable "local_domain" {
  description = "value of the local domain"
  type        = string
}

variable "node_ssh_key" {
  description = "value of the node ssh key"
  type        = string
  validation {
    condition     = can(regex("^(ssh-rsa|ssh-ed25519) [A-Za-z0-9+/]+[=]{0,3}( [^@]+@[^@]+)?$", var.node_ssh_key))
    error_message = "Invalid SSH key"
  }
}

variable "nodes" {
  description = "value of the cluster nodes"
  type = map(object({
    ip   = string
    type = string
  }))
}

variable "node_users" {
  description = "List of users to create"
  type = map(object({
    username = string
    password = string
  }))
}

variable "metallb_namespace" {
  description = "Defines the MetalLB namespace"
  default     = "metallb-system"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.metallb_namespace))
    error_message = "Invalid namespace format, should be lowercase alphanumeric"
  }
}

variable "metallb_address_pool" {
  description = "Defines the MetalLB address pool, a map of name and addresses (ip ranges or ip/mask)"
  type = object({
    name      = string
    addresses = list(string)
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
