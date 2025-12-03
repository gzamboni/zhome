variable "adguard_ip" {
  description = "IP address of the ADGuard Home instance"
  type        = string
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.adguard_ip))
    error_message = "Invalid IP address"
  }
}

variable "admin_password" {
  description = "Admin password for the AdGuard Home UI"
  type        = string
  sensitive   = true
}

variable "filters" {
  description = "List of filters to be installed"
  type = list(object({
    name    = string
    url     = string
    enabled = bool
  }))
  default = []
}

variable "rewrites" {
  description = "List of rewrites to be installed"
  type = list(object({
    hostname = string
    ip       = string
    enabled  = bool
  }))
  default = []
}

variable "user_rules" {
  description = "List of user rules to be installed"
  type        = list(string)
  default     = []
}
