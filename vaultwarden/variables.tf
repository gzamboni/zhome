variable "timezone" {
  description = "Timezone to use for the vaultwarden container"
  type        = string
  default     = "America/Sao_Paulo"
}

variable "default_vault_domain" {
  description = "Default vaultwaren domain URL"
  type        = string
}

variable "ingress_hosts" {
  description = "Ingress hosts for vaultwarden"
  type        = list(string)
}

variable "allow_signups" {
  description = "Allow signups"
  type        = bool
  default     = false
}

variable "domain_white_list" {
  description = "Domain white list"
  type        = list(string)
}

variable "org_creation_users" {
  description = "list of users that can create organizations"
  type        = list(string)
}

variable "smtp_config" {
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
    condition     = contains(["starttls", "force_tls", "off"], var.smtp_config.server.security)
    error_message = "smtp_config.server.security must be one of: starttls, force_tls, off"
  }
  validation {
    condition     = tonumber(var.smtp_config.server.timeout) > 0
    error_message = "smtp_config.server.timeout must be greater than 0"
  }
  validation {
    condition     = (var.smtp_config.server.port == "465" && var.smtp_config.server.security == "force_tls") || (contains(["587", "25"], var.smtp_config.server.port) && var.smtp_config.server.security == "starttls") || var.smtp_config.server.port == "25" && var.smtp_config.server.security == "off"
    error_message = "smtp_config.server.port and smtp_config.server.security are incompatible. See https://github.com/dani-garcia/vaultwarden/blob/9e5b049dca6438cf289619c325406d420ef97c78/.env.template#L391"
  }
}
