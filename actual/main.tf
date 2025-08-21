resource "kubernetes_namespace" "actual" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_persistent_volume_claim" "actual_data" {
  metadata {
    name      = "${var.namespace}-data"
    namespace = kubernetes_namespace.actual.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "4Gi"
      }
    }
    storage_class_name = var.storage_class_name
  }
}

resource "kubernetes_deployment" "actual" {
  metadata {
    name      = var.namespace
    namespace = kubernetes_namespace.actual.metadata[0].name
  }
  spec {
    selector {
      match_labels = {
        "app.kubernetes.io/name"     = var.namespace
        "app.kubernetes.io/instance" = var.namespace
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"     = var.namespace
          "app.kubernetes.io/instance" = var.namespace
        }
      }
      spec {
        security_context {
          fs_group = 1000
        }
        container {
          name              = var.namespace
          image             = "actualbudget/actual-server:latest-alpine"
          image_pull_policy = "IfNotPresent"
          port {
            container_port = 5006
            name           = "http"
            protocol       = "TCP"
          }
          env {
            name  = "ACTUAL_ALLOWED_LOGIN_METHODS"
            value = "'password','openid'"
          }
          env {
            name  = "ACTUAL_PORT"
            value = "5006"
          }
          volume_mount {
            mount_path = "/data"
            name       = "data"
          }
          security_context {
            run_as_user  = 1000
            run_as_group = 1000
          }
          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
          liveness_probe {
            http_get {
              path = "/"
              port = "5006"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
          readiness_probe {
            http_get {
              path = "/"
              port = "5006"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.actual_data.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "actual" {
  metadata {
    name      = var.namespace
    namespace = kubernetes_namespace.actual.metadata[0].name
    labels = {
      "app.kubernetes.io/name"     = var.namespace
      "app.kubernetes.io/instance" = var.namespace
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name"     = var.namespace
      "app.kubernetes.io/instance" = var.namespace
    }
    port {
      name        = "http"
      port        = 5006
      target_port = 5006
      protocol    = "TCP"
    }
    type = "ClusterIP"
  }

}

resource "kubernetes_ingress_v1" "actual" {
  metadata {
    name      = var.namespace
    namespace = kubernetes_namespace.actual.metadata[0].name
    labels = {
      "app.kubernetes.io/name"     = var.namespace
      "app.kubernetes.io/instance" = var.namespace
    }
  }
  spec {
    ingress_class_name = "traefik"
    rule {
      host = var.fqdn
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.actual.metadata[0].name
              port {
                number = 5006
              }
            }
          }
        }
      }
    }
  }
}
