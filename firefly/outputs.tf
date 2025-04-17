output "mysql_service_name" {
  description = "Name of the MySQL service"
  value       = kubernetes_service.mysql.metadata[0].name
}

output "mysql_service_port" {
  description = "Port of the MySQL service"
  value       = kubernetes_service.mysql.spec[0].port[0].port
}
