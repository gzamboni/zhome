output "namespace" {
  description = "The Kubernetes namespace where n8n is deployed"
  value       = kubernetes_namespace.n8n.metadata.0.name
}

output "service_name" {
  description = "The name of the n8n service"
  value       = kubernetes_service.n8n_service.metadata.0.name
}

output "ip_address" {
  description = "The IP address of the n8n service"
  value       = var.n8n_ip_address
}

output "url" {
  description = "The URL to access n8n"
  value       = "http://${var.n8n_ip_address}:${var.n8n_port}"
}

output "data_pvc_name" {
  description = "The name of the persistent volume claim for n8n data"
  value       = kubernetes_persistent_volume_claim.n8n_data_pvc.metadata.0.name
}
