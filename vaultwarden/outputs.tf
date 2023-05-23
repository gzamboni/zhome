output "admin_token" {
  description = "value of the admin token"
  value       = random_string.admin_token.result
}
