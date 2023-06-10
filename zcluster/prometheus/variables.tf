variable "domain" {
  description = "value of the domain"
  type        = string
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
