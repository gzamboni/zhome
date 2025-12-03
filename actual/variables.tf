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
