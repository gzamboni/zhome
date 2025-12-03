variable "namespace" {
  description = "The Kubernetes namespace to create"
  type        = string
  default     = "actual"
}

variable "storage_class_name" {
  description = "The storage class name to use for the PVC"
  type        = string
  default     = "longhorn"
}

variable "fqdn" {
  description = "The fully qualified domain name for the ingress"
  type        = string
  default     = "actual.example.com"
}

variable "oauth_client_id" {
  description = "OIDC client ID"
  type        = string
  sensitive   = true
}

variable "oauth_client_secret" {
  description = "OIDC client secret"
  type        = string
  sensitive   = true
}

variable "auth0_domain" {
  description = "Auth0 domain"
  type        = string
}

variable "image_tag" {
  description = "The image tag to use for the openwebui container"
  type        = string
  default     = "v0.6.30"
}
