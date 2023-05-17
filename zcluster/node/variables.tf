variable "node_ip" {
  description = "value of the node ip"
}

variable "node_hostname" {
  description = "value of the node hostname"
  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]*[$]?$", var.node_hostname))
    error_message = "Invalid hostname"
  }
}

variable "node_local_domain" {
  description = "value of the node local domain"
  default     = "local"
}

variable "node_admin_user" {
  description = "value of the node admin user"
  default     = "root"
}

variable "node_ssh_key" {
  description = "value of the node ssh key"
  validation {
    condition     = can(regex("^(ssh-rsa|ssh-ed25519) [A-Za-z0-9+/]+[=]{0,3}( [^@]+@[^@]+)?$", var.node_ssh_key))
    error_message = "Invalid SSH key"
  }
}

variable "nodes_hosts" {
  description = "value of the hosts file content"
}

variable "node_users" {
  description = "value of the node users"
}
