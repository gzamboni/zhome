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

variable "api_password" {
  description = "Password for the AdGuard Home API"
  type        = string
  sensitive   = true
}
