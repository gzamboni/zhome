terraform {
  required_version = ">=0.13"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }
  }
}

# Create namespace for Uptime Kuma
resource "kubernetes_namespace" "uptime_kuma" {
  metadata {
    name = var.namespace
  }
}

# Create persistent volume claim for Uptime Kuma data
resource "kubernetes_persistent_volume_claim" "uptime_kuma_data" {
  metadata {
    name      = "uptime-kuma-data"
    namespace = kubernetes_namespace.uptime_kuma.metadata[0].name
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

# Create deployment for Uptime Kuma
resource "kubernetes_deployment" "uptime_kuma" {
  metadata {
    name      = "uptime-kuma"
    namespace = kubernetes_namespace.uptime_kuma.metadata[0].name
    labels = {
      "app.kubernetes.io/name"     = "uptime-kuma"
      "app.kubernetes.io/instance" = "uptime-kuma"
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "uptime-kuma"
        "app.kubernetes.io/instance" = "uptime-kuma"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"     = "uptime-kuma"
          "app.kubernetes.io/instance" = "uptime-kuma"
        }
      }

      spec {
        security_context {
          fs_group = 1000
        }

        # Init container to install Chromium
        init_container {
          name  = "install-chromium"
          image = "debian:bookworm-slim"
          command = [
            "/bin/bash", "-c",
            <<-EOT
              apt-get update && \
              apt-get install -y wget chromium chromium-driver && \
              mkdir -p /tmp/chrome-bin && \
              cp /usr/bin/chromium /tmp/chrome-bin/ && \
              cp /usr/bin/chromedriver /tmp/chrome-bin/ 2>/dev/null || true
            EOT
          ]
          volume_mount {
            name       = "chrome-bin"
            mount_path = "/tmp/chrome-bin"
          }
        }

        container {
          name              = "uptime-kuma"
          image             = var.image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = var.port
            name           = "http"
            protocol       = "TCP"
          }

          env {
            name  = "TZ"
            value = var.timezone
          }

          env {
            name  = "UPTIME_KUMA_PORT"
            value = tostring(var.port)
          }

          env {
            name  = "UPTIME_KUMA_DISABLE_FRAME_SAMEORIGIN"
            value = "1"
          }

          env {
            name  = "PUID"
            value = "1000"
          }

          env {
            name  = "PGID"
            value = "1000"
          }

          env {
            name  = "CHROME_BIN"
            value = "/usr/bin/chromium"
          }

          env {
            name  = "PUPPETEER_SKIP_CHROMIUM_DOWNLOAD"
            value = "true"
          }

          env {
            name  = "PUPPETEER_EXECUTABLE_PATH"
            value = "/usr/bin/chromium"
          }

          # Custom command to copy Chromium and start uptime-kuma
          command = [
            "/bin/bash", "-c",
            <<-EOT
              # Copy Chrome from init container
              cp -r /tmp/chrome-bin/* /usr/bin/ 2>/dev/null || true && \
              chmod +x /usr/bin/chromium /usr/bin/chromedriver 2>/dev/null || true && \
              # Start uptime-kuma
              exec node server/server.js
            EOT
          ]

          volume_mount {
            name       = "chrome-bin"
            mount_path = "/tmp/chrome-bin"
          }

          volume_mount {
            name       = "data"
            mount_path = "/app/data"
          }

          # Run as root to install packages and copy files
          security_context {
            run_as_user = 0
            run_as_group = 0
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

          liveness_probe {
            http_get {
              path = "/"
              port = var.port
            }
            initial_delay_seconds = 60
            period_seconds        = 30
            timeout_seconds       = 10
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = var.port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.uptime_kuma_data.metadata[0].name
          }
        }

        volume {
          name = "chrome-bin"
          empty_dir {}
        }
      }
    }
  }
}

# Create service for Uptime Kuma
resource "kubernetes_service" "uptime_kuma" {
  metadata {
    name      = "uptime-kuma"
    namespace = kubernetes_namespace.uptime_kuma.metadata[0].name
    labels = {
      "app.kubernetes.io/name"     = "uptime-kuma"
      "app.kubernetes.io/instance" = "uptime-kuma"
    }
    annotations = var.service_type == "LoadBalancer" && var.load_balancer_ip != "" ? {
      "metallb.io/address-pool"                    = "metallb-ip-pool"
      "metallb.universe.tf/ip-allocated-from-pool" = "metallb-ip-pool"
      "metallb.universe.tf/loadBalancerIPs"        = var.load_balancer_ip
    } : {}
  }

  spec {
    selector = {
      "app.kubernetes.io/name"     = "uptime-kuma"
      "app.kubernetes.io/instance" = "uptime-kuma"
    }

    port {
      name        = "http"
      port        = var.port
      target_port = var.port
      protocol    = "TCP"
    }

    type                    = var.service_type
    external_traffic_policy = var.service_type == "LoadBalancer" ? "Local" : null
  }
}

# Create ingress for Uptime Kuma (if enabled)
resource "kubernetes_ingress_v1" "uptime_kuma" {
  count = var.ingress_enabled ? 1 : 0

  metadata {
    name      = "uptime-kuma"
    namespace = kubernetes_namespace.uptime_kuma.metadata[0].name
    labels = {
      "app.kubernetes.io/name"     = "uptime-kuma"
      "app.kubernetes.io/instance" = "uptime-kuma"
    }
  }

  spec {
    ingress_class_name = var.ingress_class

    dynamic "rule" {
      for_each = var.ingress_hosts
      content {
        host = rule.value
        http {
          path {
            path      = "/"
            path_type = "Prefix"
            backend {
              service {
                name = kubernetes_service.uptime_kuma.metadata[0].name
                port {
                  number = var.port
                }
              }
            }
          }
        }
      }
    }
  }
}
