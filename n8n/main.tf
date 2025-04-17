resource "kubernetes_namespace" "n8n" {
  metadata {
    name = var.n8n_namespace
  }
}

resource "kubernetes_persistent_volume_claim" "n8n_data_pvc" {
  metadata {
    name      = "n8n-data"
    namespace = kubernetes_namespace.n8n.metadata.0.name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.n8n_data_storage_size
      }
    }
    storage_class_name = var.storage_class_name
  }
}

resource "kubernetes_deployment" "n8n_deployment" {
  metadata {
    name      = "n8n"
    namespace = kubernetes_namespace.n8n.metadata.0.name
  }

  spec {
    replicas = var.n8n_replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "n8n"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "n8n"
          app                      = "n8n"
        }
      }

      spec {
        # Add security context for the pod
        security_context {
          fs_group    = 1000 # This is the group ID for the 'node' user in the n8n container
          run_as_user = 1000 # This is the user ID for the 'node' user in the n8n container
        }

        # Add init container to set permissions
        init_container {
          name    = "init-permissions"
          image   = "busybox:latest"
          command = ["/bin/sh", "-c", "chown -R 1000:1000 /home/node/.n8n"]

          volume_mount {
            name       = kubernetes_persistent_volume_claim.n8n_data_pvc.metadata.0.name
            mount_path = "/home/node/.n8n"
            read_only  = false
          }

          security_context {
            run_as_user = 0 # Run as root to be able to change permissions
          }
        }
        container {
          name              = "n8n"
          image             = var.n8n_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = var.n8n_port
            name           = "http"
            protocol       = "TCP"
          }

          resources {
            limits = {
              cpu    = var.n8n_resources_limits_cpu
              memory = var.n8n_resources_limits_memory
            }
            requests = {
              cpu    = var.n8n_resources_requests_cpu
              memory = var.n8n_resources_requests_memory
            }
          }

          volume_mount {
            name       = kubernetes_persistent_volume_claim.n8n_data_pvc.metadata.0.name
            mount_path = "/home/node/.n8n"
            read_only  = false
          }

          env {
            name  = "N8N_PORT"
            value = var.n8n_port
          }

          env {
            name  = "TZ"
            value = var.n8n_timezone
          }

          dynamic "env" {
            for_each = var.n8n_encryption_key != "" ? [1] : []
            content {
              name  = "N8N_ENCRYPTION_KEY"
              value = var.n8n_encryption_key
            }
          }

          dynamic "env" {
            for_each = var.n8n_webhook_url != "" ? [1] : []
            content {
              name  = "WEBHOOK_URL"
              value = var.n8n_webhook_url
            }
          }

          # Basic authentication
          dynamic "env" {
            for_each = var.n8n_basic_auth_user != "" && var.n8n_basic_auth_password != "" ? [1] : []
            content {
              name  = "N8N_BASIC_AUTH_ACTIVE"
              value = "true"
            }
          }

          dynamic "env" {
            for_each = var.n8n_basic_auth_user != "" ? [1] : []
            content {
              name  = "N8N_BASIC_AUTH_USER"
              value = var.n8n_basic_auth_user
            }
          }

          dynamic "env" {
            for_each = var.n8n_basic_auth_password != "" ? [1] : []
            content {
              name  = "N8N_BASIC_AUTH_PASSWORD"
              value = var.n8n_basic_auth_password
            }
          }

          # Database configuration
          dynamic "env" {
            for_each = var.n8n_db_type != "sqlite" ? [1] : []
            content {
              name  = "DB_TYPE"
              value = var.n8n_db_type
            }
          }

          dynamic "env" {
            for_each = var.n8n_db_type != "sqlite" ? [1] : []
            content {
              name  = "DB_HOST"
              value = var.n8n_db_host
            }
          }

          dynamic "env" {
            for_each = var.n8n_db_type != "sqlite" ? [1] : []
            content {
              name  = "DB_PORT"
              value = var.n8n_db_port
            }
          }

          dynamic "env" {
            for_each = var.n8n_db_type != "sqlite" ? [1] : []
            content {
              name  = "DB_DATABASE"
              value = var.n8n_db_name
            }
          }

          dynamic "env" {
            for_each = var.n8n_db_type != "sqlite" ? [1] : []
            content {
              name  = "DB_USER"
              value = var.n8n_db_user
            }
          }

          dynamic "env" {
            for_each = var.n8n_db_type != "sqlite" && var.n8n_db_password != "" ? [1] : []
            content {
              name  = "DB_PASSWORD"
              value = var.n8n_db_password
            }
          }
        }

        volume {
          name = kubernetes_persistent_volume_claim.n8n_data_pvc.metadata.0.name
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.n8n_data_pvc.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "n8n_service" {
  metadata {
    name      = "n8n-service"
    namespace = kubernetes_namespace.n8n.metadata.0.name
    annotations = {
      "metallb.io/address-pool" : "metallb-ip-pool"
      "metallb.universe.tf/ip-allocated-from-pool" = "metallb-ip-pool"
      "metallb.universe.tf/loadBalancerIPs"        = var.n8n_ip_address
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "n8n"
    }

    port {
      port        = var.n8n_port
      target_port = var.n8n_port
      protocol    = "TCP"
      name        = "http"
    }

    type                    = "LoadBalancer"
    external_traffic_policy = "Local"
  }
}
