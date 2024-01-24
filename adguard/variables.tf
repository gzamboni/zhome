variable "adguard_ip" {
  description = "IP address of the ADGuard Home instance"
  type        = string
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.adguard_ip))
    error_message = "Invalid IP address"
  }
}

variable "api_password" {
  description = "Password for the AdGuard Home API"
  type        = string
}

variable "admin_token" {
  description = "Admin token for the AdGuard Home API"
  type        = string
}

variable "filters" {
  description = "List of filters to be installed"
  type = list(object({
    name    = string
    url     = string
    enabled = bool
  }))
}

variable "rewrites" {
  description = "List of rewrites to be installed"
  type = list(object({
    hostname = string
    ip       = string
    enabled  = bool
  }))
}

variable "user_rules" {
  description = "List of user rules to be installed"
  type        = list(string)
}
