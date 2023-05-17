terraform {
  required_version = ">= 0.13.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
  }
}

resource "kubernetes_namespace" "longhorn_storage" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "longhorn_storage" {
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  namespace  = kubernetes_namespace.longhorn_storage.metadata[0].name
  depends_on = [kubernetes_namespace.longhorn_storage]
  set {
    name  = "defaultSettings.defaultDataPath"
    value = var.data_path
  }
}

resource "kubernetes_ingress_v1" "longhorn_ui" {
  wait_for_load_balancer = true
  metadata {
    name      = "longhorn-ui"
    namespace = kubernetes_namespace.longhorn_storage.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"
    }
  }
  spec {
    default_backend {
      service {
        name = "longhorn-frontend"
        port {
          name = "http"
        }
      }
    }
    rule {
      host = "longhorn.${var.domain}"
      http {
        path {
          backend {
            service {
              name = "longhorn-frontend"
              port {
                name = "http"
              }
            }
          }
          path = "/"
        }
      }
    }
  }
}
