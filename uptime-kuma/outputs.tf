output "namespace" {
  description = "Kubernetes namespace where Uptime Kuma is deployed"
  value       = kubernetes_namespace.uptime_kuma.metadata[0].name
}

output "service_name" {
  description = "Name of the Uptime Kuma service"
  value       = kubernetes_service.uptime_kuma.metadata[0].name
}

output "service_port" {
  description = "Port of the Uptime Kuma service"
  value       = kubernetes_service.uptime_kuma.spec[0].port[0].port
}

output "service_type" {
  description = "Type of the Uptime Kuma service"
  value       = kubernetes_service.uptime_kuma.spec[0].type
}

output "load_balancer_ip" {
  description = "Load balancer IP address (if service type is LoadBalancer)"
  value       = var.service_type == "LoadBalancer" ? var.load_balancer_ip : null
}

output "ingress_hosts" {
  description = "Ingress hostnames for Uptime Kuma"
  value       = var.ingress_enabled ? var.ingress_hosts : []
}

output "deployment_name" {
  description = "Name of the Uptime Kuma deployment"
  value       = kubernetes_deployment.uptime_kuma.metadata[0].name
}

output "pvc_name" {
  description = "Name of the persistent volume claim for Uptime Kuma data"
  value       = kubernetes_persistent_volume_claim.uptime_kuma_data.metadata[0].name
}
