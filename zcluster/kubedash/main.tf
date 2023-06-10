resource "random_string" "dashboard_csrf" {
  length  = 40
  special = false
}

module "kubernetes_dashboard" {
  source                                          = "cookielab/dashboard/kubernetes"
  version                                         = "0.9.0"
  kubernetes_deployment_metrics_scraper_image_tag = "v1.0.2"
  kubernetes_namespace_create                     = true
  kubernetes_dashboard_csrf                       = random_string.dashboard_csrf.result
}

