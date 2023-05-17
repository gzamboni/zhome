variable "domain" {
  description = "value of the domain"
  default     = "k3s.zhome.local"
}

variable "data_path" {
  description = "value of the data path"
  default     = "/storage"
}

variable "namespace" {
  type        = string
  description = "value of the namespace"
  default     = "longhorn-system"
}
