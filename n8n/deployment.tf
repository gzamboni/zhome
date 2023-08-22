locals {
  n8n_container_port = 5678
  n8n_image          = "n8nio/n8n:latest"
}

resource "kubernetes_deployment" "n8n" {
  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.n8n_config,
      kubernetes_secret.n8n_config
    ]
  }
  metadata {
    name      = "n8n"
    namespace = kubernetes_namespace.n8n.metadata[0].name
    labels = {
      app       = "n8n"
      component = "deployment"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "n8n"
      }
    }
    template {
      metadata {
        labels = {
          app = "n8n"
        }
      }
      spec {
        container {
          name              = "n8n"
          image             = local.n8n_image
          image_pull_policy = "IfNotPresent"

          resources {
            limits = {
              cpu    = "1"
              memory = "1Gi"
            }
            requests = {
              cpu    = "500m"
              memory = "500Mi"
            }
          }

          port {
            container_port = local.n8n_container_port
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.n8n_config.metadata.0.name
            }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.n8n_config.metadata.0.name
            }
          }
          liveness_probe {
            http_get {
              path = "/healthz"
              port = local.n8n_container_port
            }
          }
          readiness_probe {
            http_get {
              path = "/healthz"
              port = local.n8n_container_port
            }
          }
        }
      }
    }
  }
  depends_on = [
    postgresql_database.n8n_db,
    postgresql_role.n8n_db_user,
    postgresql_grant.n8n_admin
  ]
}
