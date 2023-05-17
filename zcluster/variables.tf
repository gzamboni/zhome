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
