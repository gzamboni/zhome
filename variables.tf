variable "kubeconfig" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "k3s_config" {
  description = "Object containing k3s configuration"
  type = object({
    cluster_name = string
    local_domain = string
    context      = string
    nodes = map(object({
      ip   = string
      type = string
    }))
    users = map(object({
      username = string
      password = string
    }))
  })
}

variable "metallb_address_pool" {
  description = "Defines the MetalLB address pool, a map of name and addresses (ip ranges or ip/mask)"
  type = object({
    name      = string
    addresses = list(string)
  })
}
