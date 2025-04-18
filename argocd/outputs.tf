output "namespace" {
  description = "The Kubernetes namespace where ArgoCD is deployed"
  value       = kubernetes_namespace.argocd.metadata.0.name
}

output "server_service_name" {
  description = "The name of the ArgoCD server service"
  value       = "argocd-server"
}

output "ip_address" {
  description = "The IP address of the ArgoCD server service"
  value       = var.argocd_ip_address
}

output "url" {
  description = "The URL to access ArgoCD UI"
  value       = "http://${var.argocd_ip_address}:${var.argocd_server_port}"
}

output "api_url" {
  description = "The URL to access ArgoCD API"
  value       = "http://${var.argocd_ip_address}:${var.argocd_server_port}/api"
}

output "repo_server_service_name" {
  description = "The name of the ArgoCD repo server service"
  value       = "argocd-repo-server"
}

output "application_controller_service_name" {
  description = "The name of the ArgoCD application controller service"
  value       = "argocd-application-controller"
}

output "projects" {
  description = "The ArgoCD projects created"
  value       = [for project in kubectl_manifest.argocd_project : project.name]
}

output "repositories" {
  description = "The Git repositories configured in ArgoCD"
  value       = var.argocd_repositories
  sensitive   = true
}
