variable "username" {
  description = "value of the node user"
  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]*[$]?$", var.username))
    error_message = "Invalid user name"
  }
}

variable "password" {
  description = "value of the node password"
}

variable "ssh_key" {
  description = "value of the node ssh key"
  validation {
    condition     = can(regex("^(ssh-rsa|ssh-ed25519) [A-Za-z0-9+/]+[=]{0,3}( [^@]+@[^@]+)?$", var.ssh_key))
    error_message = "Invalid SSH key"
  }
}

variable "host_ip" {
  description = "value of the node ip"
}

variable "host_user" {
  description = "value of the node user"
  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]*[$]?$", var.host_user))
    error_message = "Invalid user name"
  }
  default = "root"
}

