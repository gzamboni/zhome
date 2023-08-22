variable "postgresql_cluster_host" {
  type = string
}

variable "n8n_config" {
  type = object({
    auth = object({
      username = string
      password = string
    })
    domains = object({
      internal = string
      external = string
    })
  })
}
