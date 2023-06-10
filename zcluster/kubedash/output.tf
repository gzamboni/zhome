output "kubernetes_dashboard_csrf" {
  value = random_string.dashboard_csrf.result
}
