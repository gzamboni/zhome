variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "secret_key" {
  description = "Secret key for FrameOS"
  type        = string
}
