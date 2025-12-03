output "adguard_ip" {
  description = "The IP address of the AdGuard Home LoadBalancer service"
  value       = var.adguard_ip
}

output "adguard_service_name" {
  description = "The name of the AdGuard Home Kubernetes service"
  value       = kubernetes_service.adguard.metadata[0].name
}

output "adguard_namespace" {
  description = "The namespace where AdGuard Home is deployed"
  value       = kubernetes_namespace.adguard.metadata[0].name
}
