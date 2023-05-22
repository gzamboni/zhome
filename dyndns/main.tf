terraform {
  required_version = ">=0.13"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
  }
}

resource "kubernetes_namespace" "inadyn" {
  metadata {
    name = "inadyn"
    labels = {
      app = "inadyn"
    }
  }
}

# resource "kubernetes_namespace" "ddclient" {
#   metadata {
#     name = "ddclient"
#     labels = {
#       app = "ddclient"
#     }
#   }
# }

# resource "kubernetes_secret" "ddclient_secret" {
#   metadata {
#     name      = "ddclient"
#     namespace = kubernetes_namespace.ddclient.metadata[0].name
#   }
#   data = {
#     "ddclient.conf" = <<-EOF
#     ssl=yes
#     protocol=dyndns2
#     use=web
#     server=domains.google.com
#     login=${var.google_dynamic_dns_username}
#     password=${var.google_dynamic_dns_password}
#     ${var.google_dynamic_dns_fqdn}
#     EOF
#   }
# }

# resource "kubernetes_deployment" "ddclient" {
#   metadata {
#     name      = "ddclient"
#     namespace = kubernetes_namespace.ddclient.metadata[0].name
#     labels = {
#       app = "ddclient"
#     }
#   }
#   spec {
#     strategy {
#       type = "RollingUpdate"
#       rolling_update {
#         max_surge       = 1
#         max_unavailable = 1
#       }
#     }
#     replicas = 1
#     selector {
#       match_labels = {
#         app = "ddclient"
#       }
#     }
#     template {
#       metadata {
#         labels = {
#           app = "ddclient"
#         }
#       }
#       spec {
#         volume {
#           name = "ddclient-config-file"
#           secret {
#             secret_name = kubernetes_secret.ddclient_secret.metadata[0].name
#           }
#         }
#         container {
#           name              = "ddclient"
#           image             = "linuxserver/ddclient"
#           image_pull_policy = "Always"
#           volume_mount {
#             name       = "ddclient-config-file"
#             mount_path = "/defaults"
#             read_only  = false
#           }
#           resources {
#             limits = {
#               cpu    = "50m"
#               memory = "128Mi"
#             }
#             requests = {
#               cpu    = "10m"
#               memory = "64Mi"
#             }
#           }
#         }
#       }
#     }
#   }
# }

resource "helm_release" "inadyn" {
  name            = "inadyn"
  repository      = "https://charts.philippwaller.com"
  chart           = "inadyn"
  namespace       = kubernetes_namespace.inadyn.metadata[0].name
  cleanup_on_fail = true
  depends_on      = [kubernetes_namespace.inadyn]
  set {
    name  = "inadynConfig"
    value = <<-EOF
    # Inadyn v2.0 configuration file format
    period          = 300

    provider default@domains.google.com {
        ssl         = true
        username    = ${var.google_dynamic_dns_username}
        password    = ${var.google_dynamic_dns_password}
        hostname    = ${var.google_dynamic_dns_fqdn}
    }
    EOF
  }
}
