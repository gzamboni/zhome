output "postgresql_external_ip" {
  value = kubernetes_service.postgresql_service.status.0.load_balancer.0.ingress.0.ip
}

output "postgresql_service_host" {
  value = "${kubernetes_service.postgresql_service.metadata[0].name}.${kubernetes_service.postgresql_service.metadata[0].namespace}.svc.cluster.local"
}
