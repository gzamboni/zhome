variable "namespace" {
  description = "Kubernetes namespace for DNS updater jobs"
  type        = string
  default     = "cloudflare-dns-updater"
}

variable "cloudflare_email" {
  description = "Cloudflare account email"
  type        = string
}

variable "cloudflare_api_key" {
  description = "Cloudflare Global API Key"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for zamboni.dev"
  type        = string
}

variable "schedule" {
  description = "Cron schedule for the DNS update jobs"
  type        = string
  default     = "*/5 * * * *" # Every 5 minutes
}

variable "link1_config" {
  description = "Configuration for the first internet link"
  type = object({
    provider    = string
    record_name = string
    node_name   = string
  })
  default = {
    provider    = "internet1"
    record_name = "host1"
    node_name   = "node1"
  }
}

variable "link2_config" {
  description = "Configuration for the second internet link"
  type = object({
    provider    = string
    record_name = string
    node_name   = string
  })
  default = {
    provider    = "internet2"
    record_name = "host2"
    node_name   = "node2"
  }
}

variable "domain" {
  description = "Domain name for the DNS records"
  type        = string
  default     = "example.com"
}

variable "resources" {
  description = "Resource limits and requests for the jobs"
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
      cpu    = "100m"
      memory = "128Mi"
    }
    requests = {
      cpu    = "50m"
      memory = "64Mi"
    }
  }
}
