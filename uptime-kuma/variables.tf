variable "namespace" {
  description = "Kubernetes namespace for Uptime Kuma"
  type        = string
  default     = "uptime-kuma"
}

variable "image" {
  description = "Uptime Kuma Docker image"
  type        = string
  default     = "louislam/uptime-kuma:1"
}

variable "replicas" {
  description = "Number of replicas for Uptime Kuma deployment"
  type        = number
  default     = 1
}

variable "port" {
  description = "Port for Uptime Kuma service"
  type        = number
  default     = 3001
}

variable "storage_class_name" {
  description = "Storage class name for persistent volume"
  type        = string
  default     = "longhorn"
}

variable "storage_size" {
  description = "Storage size for Uptime Kuma data"
  type        = string
  default     = "2Gi"
}

variable "resources" {
  description = "Resource limits and requests for Uptime Kuma"
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
}

variable "ingress_enabled" {
  description = "Enable ingress for Uptime Kuma"
  type        = bool
  default     = true
}

variable "ingress_class" {
  description = "Ingress class name"
  type        = string
  default     = "traefik"
}

variable "ingress_hosts" {
  description = "List of hostnames for ingress"
  type        = list(string)
  default     = []
}

variable "service_type" {
  description = "Kubernetes service type"
  type        = string
  default     = "ClusterIP"
  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.service_type)
    error_message = "Service type must be one of: ClusterIP, NodePort, LoadBalancer"
  }
}

variable "load_balancer_ip" {
  description = "Load balancer IP address (only used when service_type is LoadBalancer)"
  type        = string
  default     = ""
}

variable "timezone" {
  description = "Timezone for Uptime Kuma"
  type        = string
  default     = "UTC"
}
