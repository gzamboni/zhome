resource "kubernetes_secret" "mysql_secret" {
  metadata {
    name      = "mysql-secret"
    namespace = kubernetes_namespace.firefly.metadata[0].name
  }

  data = {
    mysql-root-password = var.mysql_root_password
    mysql-password      = var.mysql_password
  }
}

resource "kubernetes_persistent_volume_claim" "mysql" {
  metadata {
    name      = "mysql-pvc"
    namespace = kubernetes_namespace.firefly.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.mysql_storage_size
      }
    }
    storage_class_name = "longhorn-nvme"
  }
}

resource "kubernetes_deployment" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace.firefly.metadata[0].name
    labels = {
      app = "mysql"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mysql"
      }
    }

    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }

      spec {
        container {
          name  = "mysql"
          image = "mysql:8.0"

          port {
            container_port = 3306
          }

          env {
            name = "MYSQL_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql_secret.metadata[0].name
                key  = "mysql-root-password"
              }
            }
          }

          env {
            name = "MYSQL_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql_secret.metadata[0].name
                key  = "mysql-password"
              }
            }
          }

          env {
            name  = "MYSQL_DATABASE"
            value = var.mysql_database
          }

          env {
            name  = "MYSQL_USER"
            value = var.mysql_user
          }

          resources {
            limits = {
              cpu    = var.mysql_cpu_limit
              memory = var.mysql_memory_limit
            }
            requests = {
              cpu    = var.mysql_cpu_request
              memory = var.mysql_memory_request
            }
          }

          volume_mount {
            name       = "mysql-persistent-storage"
            mount_path = "/var/lib/mysql"
          }

          liveness_probe {
            exec {
              command = ["mysqladmin", "ping"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
          }

          readiness_probe {
            exec {
              command = ["mysql", "-h", "127.0.0.1", "-e", "SELECT 1"]
            }
            initial_delay_seconds = 5
            period_seconds        = 2
            timeout_seconds       = 1
          }
        }

        volume {
          name = "mysql-persistent-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mysql.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace.firefly.metadata[0].name
  }
  spec {
    selector = {
      app = kubernetes_deployment.mysql.metadata[0].labels.app
    }
    port {
      port        = 3306
      target_port = 3306
    }
    type = "ClusterIP"
  }
}
