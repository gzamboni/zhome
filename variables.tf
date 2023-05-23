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
