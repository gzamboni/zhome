variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "monocle_gateway_ip_address" {
  description = "IP address for the monocle gateway service"
  type        = string
  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.monocle_gateway_ip_address))
    error_message = "Invalid IP address"
  }
}

variable "monocle_token" {
  description = "Monocle token"
  type        = string
}

variable "nginx_proxy_manager_ip_address" {
  description = "IP address for the nginx proxy manager service"
  type        = string
  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.nginx_proxy_manager_ip_address))
    error_message = "Invalid IP address"
  }
}
