resource "kubernetes_namespace" "openwebui" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_persistent_volume_claim" "openwebui_data" {
  metadata {
    name      = "${var.namespace}-data"
    namespace = kubernetes_namespace.openwebui.metadata[0].name
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

resource "kubernetes_deployment" "openwebui" {
  metadata {
    name      = var.namespace
    namespace = kubernetes_namespace.openwebui.metadata[0].name
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
          image             = "ghcr.io/open-webui/open-webui:main"
          image_pull_policy = "IfNotPresent"
          port {
            container_port = 8080
            name           = "http"
            protocol       = "TCP"
          }

          volume_mount {
            mount_path = "/app/backend/data"
            name       = "data"
          }

          env {
            name  = "WEBUI_URL"
            value = var.fqdn
          }

          env {
            name  = "ENABLE_SIGNUP"
            value = true
          }

          env {
            name  = "OLLAMA_BASE_URL"
            value = "http://192.168.0.44:11434"
          }

          env {
            name  = "OAUTH_CLIENT_ID"
            value = var.oauth_client_id
          }
          env {
            name = "OAUTH_CLIENT_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.openwebui_oidc.metadata[0].name
                key  = "OAUTH_CLIENT_SECRET"
              }
            }
          }
          env {
            name  = "OPENID_PROVIDER_URL"
            value = "https://${var.auth0_domain}/.well-known/openid-configuration"
          }
          env {
            name  = "OAUTH_PROVIDER_NAME"
            value = "Auth0"
          }

          env {
            name  = "OAUTH_SCOPES"
            value = "openid email profile"
          }

          env {
            name  = "OPENID_REDIRECT_URI"
            value = "http://${var.fqdn}/oauth/oidc/callback"
          }

          env {
            name  = "OAUTH_ALLOWED_ROLES"
            value = "user"
          }

          env {
            name  = "OAUTH_ADMIN_ROLES"
            value = "admin"
          }

          env {
            name  = "GLOBAL_LOG_LEVEL"
            value = "WARNING"
          }

          resources {
            limits = {
              cpu    = "1"
              memory = "3Gi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
          liveness_probe {
            http_get {
              path = "/"
              port = "8080"
            }
            initial_delay_seconds = 60
            period_seconds        = 10
          }
          readiness_probe {
            http_get {
              path = "/"
              port = "8080"
            }
            initial_delay_seconds = 60
            period_seconds        = 10
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.openwebui_data.metadata[0].name
          }
        }
        node_selector = {
          "kubernetes.io/hostname" = "zcm03"
        }
      }
    }
  }
}

resource "kubernetes_service" "openwebui" {
  metadata {
    name      = var.namespace
    namespace = kubernetes_namespace.openwebui.metadata[0].name
    labels = {
      "app.kubernetes.io/name"     = var.namespace
      "app.kubernetes.io/instance" = var.namespace
    }
    annotations = {
      "traefik.enable" = "true"
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name"     = var.namespace
      "app.kubernetes.io/instance" = var.namespace
    }
    port {
      name        = "http"
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }
    type = "ClusterIP"
  }

}

resource "kubernetes_ingress_v1" "openwebui" {
  metadata {
    name      = var.namespace
    namespace = kubernetes_namespace.openwebui.metadata[0].name
    labels = {
      "app.kubernetes.io/name"     = var.namespace
      "app.kubernetes.io/instance" = var.namespace
    }
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "web"
      "traefik.ingress.kubernetes.io/router.tls"         = "false"
      "traefik.ingress.kubernetes.io/router.priority"    = "100"
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
              name = kubernetes_service.openwebui.metadata[0].name
              port {
                name = "http"
              }
            }
          }
        }
      }
    }
  }
}
