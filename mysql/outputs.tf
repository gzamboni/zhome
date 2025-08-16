output "namespace" {
  description = "The Kubernetes namespace where MySQL is deployed"
  value       = local.namespace
}

output "service_name" {
  description = "The name of the MySQL Kubernetes service"
  value       = kubernetes_service.mysql.metadata[0].name
}

output "service_cluster_ip" {
  description = "The cluster IP of the MySQL Kubernetes service"
  value       = kubernetes_service.mysql.spec[0].cluster_ip
}

output "mysql_port" {
  description = "The port on which MySQL is exposed"
  value       = kubernetes_service.mysql.spec[0].port[0].port
}

output "mysql_connection_string" {
  description = "MySQL connection string for applications"
  value       = "mysql://${var.mysql_user}:${var.mysql_password}@${var.external_fqdn != "" ? var.external_fqdn : "${kubernetes_service.mysql.metadata[0].name}.${local.namespace}.svc.cluster.local"}:3306/${var.mysql_database}"
  sensitive   = true
}

output "mysql_host" {
  description = "MySQL host for applications (internal cluster DNS)"
  value       = "${kubernetes_service.mysql.metadata[0].name}.${local.namespace}.svc.cluster.local"
}

output "mysql_external_host" {
  description = "External MySQL host FQDN via Traefik Ingress (if configured)"
  value       = var.external_fqdn != "" ? var.external_fqdn : null
}

output "mysql_ingress_name" {
  description = "Name of the MySQL Ingress resource (if created)"
  value       = var.external_fqdn != "" ? kubernetes_ingress_v1.mysql[0].metadata[0].name : null
}

output "mysql_database" {
  description = "MySQL database name"
  value       = var.mysql_database
}

output "mysql_user" {
  description = "MySQL username"
  value       = var.mysql_user
}

output "secret_name" {
  description = "Name of the Kubernetes secret containing MySQL passwords"
  value       = kubernetes_secret.mysql_secret.metadata[0].name
}

output "pvc_name" {
  description = "Name of the Persistent Volume Claim used by MySQL"
  value       = kubernetes_persistent_volume_claim.mysql.metadata[0].name
}

output "deployment_name" {
  description = "Name of the MySQL deployment"
  value       = kubernetes_deployment.mysql.metadata[0].name
}
