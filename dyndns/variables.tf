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
