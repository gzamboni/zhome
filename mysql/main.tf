# MySQL Kubernetes Module

# Create namespace if enabled
resource "kubernetes_namespace" "mysql" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

locals {
  # Use the created namespace or the existing one
  namespace = var.create_namespace ? kubernetes_namespace.mysql[0].metadata[0].name : var.namespace
}

# Secret for MySQL passwords
resource "kubernetes_secret" "mysql_secret" {
  metadata {
    name      = "${var.name}-secret"
    namespace = local.namespace
    labels = merge({
      "app.kubernetes.io/name"       = var.name
      "app.kubernetes.io/component"  = "database"
      "app.kubernetes.io/managed-by" = "terraform"
    }, var.labels)
    annotations = {
      "traefik.enable"                                   = "true"
      "traefik.tcp.routers.db.rule"                      = "HostSNI(`${var.external_fqdn}`)"
      "traefik.tcp.services.db.loadbalancer.server.port" = "3306"
      "traefik.tcp.routers.db.entrypoints"               = "mysql"
    }
  }

  data = {
    mysql-root-password = var.mysql_root_password
    mysql-password      = var.mysql_password
  }
}

# Persistent Volume Claim for MySQL data
resource "kubernetes_persistent_volume_claim" "mysql" {
  metadata {
    name      = "${var.name}-pvc"
    namespace = local.namespace
    labels = merge({
      "app.kubernetes.io/name"       = var.name
      "app.kubernetes.io/component"  = "database"
      "app.kubernetes.io/managed-by" = "terraform"
    }, var.labels)
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.storage_size
      }
    }
    storage_class_name = var.storage_class_name
  }
}

# MySQL Deployment
resource "kubernetes_deployment" "mysql" {
  metadata {
    name      = var.name
    namespace = local.namespace
    labels = merge({
      "app.kubernetes.io/name"       = var.name
      "app.kubernetes.io/component"  = "database"
      "app.kubernetes.io/managed-by" = "terraform"
    }, var.labels)
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name"      = var.name
        "app.kubernetes.io/component" = "database"
      }
    }

    template {
      metadata {
        labels = merge({
          "app.kubernetes.io/name"       = var.name
          "app.kubernetes.io/component"  = "database"
          "app.kubernetes.io/managed-by" = "terraform"
        }, var.labels)
      }

      spec {
        node_selector = var.node_selector

        container {
          name  = "mysql"
          image = "${var.image_repository}:${var.image_tag}"

          port {
            container_port = 3306
            name           = "mysql"
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
              cpu    = var.resources.limits.cpu
              memory = var.resources.limits.memory
            }
            requests = {
              cpu    = var.resources.requests.cpu
              memory = var.resources.requests.memory
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/mysql"
          }

          liveness_probe {
            exec {
              command = ["mysqladmin", "ping"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            exec {
              command = ["mysql", "-h", "127.0.0.1", "-u", "root", "-p${var.mysql_root_password}", "-e", "SELECT 1"]
            }
            initial_delay_seconds = 5
            period_seconds        = 2
            timeout_seconds       = 1
            failure_threshold     = 3
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mysql.metadata[0].name
          }
        }
      }
    }
  }
}

# MySQL Service
resource "kubernetes_service" "mysql" {
  metadata {
    name      = var.name
    namespace = local.namespace
    labels = merge({
      "app.kubernetes.io/name"       = var.name
      "app.kubernetes.io/component"  = "database"
      "app.kubernetes.io/managed-by" = "terraform"
    }, var.labels)
  }

  spec {
    selector = {
      "app.kubernetes.io/name"      = var.name
      "app.kubernetes.io/component" = "database"
    }

    port {
      port        = 3306
      target_port = 3306
      name        = "mysql"
      node_port   = 30306 # Using a valid NodePort in the range 30000-32767
    }

    type = "NodePort" # Change to NodePort to make it accessible from outside
  }
}

# Note: MySQL Ingress has been replaced with TCP Ingress
# See traefik-config.tf for the TCP ingress configuration
