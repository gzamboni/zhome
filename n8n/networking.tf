resource "kubernetes_service_v1" "n8n_service" {
  metadata {
    name      = "n8n"
    namespace = kubernetes_namespace.n8n.metadata[0].name
    labels = {
      app       = "n8n"
      component = "service"
    }
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = kubernetes_deployment.n8n.metadata[0].labels.app
    }
    port {
      port        = "5678"
      target_port = local.n8n_container_port
    }
  }
  depends_on = [kubernetes_deployment.n8n]
}

# resource "kubernetes_endpoints_v1" "n8n" {
#   metadata {
#     name      = "n8n"
#     namespace = kubernetes_namespace.n8n.metadata[0].name
#     labels = {
#       app       = "n8n"
#       component = "endpoints"
#     }
#   }
#   subset {
#     address {
#       ip = kubernetes_service.n8n_service.spec[0].cluster_ip
#     }
#     port {
#       port = "5678"
#     }
#   }
#   depends_on = [kubernetes_service.n8n_service]
# }

# # resource "kubernetes_manifest" "n8n_servertransport_internal" {
# #   manifest = {
# #     "apiVersion" = "traefik.containo.us/v1alpha1"
# #     "kind"       = "ServersTransport"
# #     "metadata" = {
# #       "name"      = "n8n-servertransport"
# #       "namespace" = kubernetes_namespace.n8n.metadata[0].name
# #     }
# #     "spec" = {
# #       "serverName" = "n8n.${var.n8n_config.domains.internal}"
# #     }
# #   }
# # }

resource "kubernetes_ingress_v1" "n8n_ingress_internal" {
  wait_for_load_balancer = true
  metadata {
    name      = "n8n-internal"
    namespace = kubernetes_namespace.n8n.metadata[0].name
    labels = {
      app       = "n8n"
      component = "ingress"
    }
    annotations = {
      "kubernetes.io/ingress.class" : "traefik"
    }
  }
  spec {
    ingress_class_name = "traefik"
    rule {
      host = "n8n.${var.n8n_config.domains.internal}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.n8n_service.metadata[0].name
              port {
                number = 5678
              }
            }
          }
        }
      }
    }
    rule {
      host = "wh.${var.n8n_config.domains.external}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.n8n_service.metadata[0].name
              port {
                number = 5678
              }
            }
          }
        }
      }
    }
  }
}
