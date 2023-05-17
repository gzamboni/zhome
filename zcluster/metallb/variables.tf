variable "namespace" {
  description = "Defines the MetalLB namespace"
  default     = "metallb-system"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.namespace))
    error_message = "Invalid namespace format, should be lowercase alphanumeric"
  }
}

variable "address_pool" {
  description = "Defines the MetalLB address pool, a map of name and addresses (ip ranges or ip/mask)"
  type = object({
    name      = string
    addresses = list(string)
  })
}

variable "l2_advertisement_name" {
  description = "value of the l2 advertisement name"
  type        = string
  default     = "l2advertisement"
}
