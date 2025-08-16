# Kubernetes provider configuration for MySQL module

# Provider configuration
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}
