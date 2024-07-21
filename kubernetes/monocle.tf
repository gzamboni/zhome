resource "kubernetes_namespace" "monocle" {
  metadata {
    name = "monocle"
  }
}

resource "kubernetes_secret" "monocle_token" {
  metadata {
    name      = "monocle-token"
    namespace = kubernetes_namespace.monocle.metadata.0.name
  }

  data = {
    monocle-token      = var.monocle_token
    monocle-properties = <<-EOF
    rtsp.register.host=${var.monocle_gateway_ip_address}
    EOF
  }
}

# Create all resources to deploy the Monocle Gateway service
resource "kubernetes_deployment" "monocle_gateway" {
  metadata {
    name      = "monocle-gateway"
    namespace = kubernetes_namespace.monocle.metadata.0.name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "monocle-gateway"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "monocle-gateway"
          app                      = "monocle-gateway"
        }
      }

      spec {
        container {
          name              = "monocle-gateway"
          image             = "monoclecam/monocle-gateway:latest"
          image_pull_policy = "Always"


          port {
            container_port = 443
            name           = "https"
            protocol       = "TCP"
          }

          port {
            container_port = 8555
            name           = "rtsp"
            protocol       = "TCP"
          }

          port {
            container_port = 8554
            name           = "proxy"
            protocol       = "TCP"
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
          volume_mount {
            name       = "monocle-token"
            mount_path = "/etc/monocle"
            read_only  = true
          }
        }
        volume {
          name = "monocle-token"
          secret {
            secret_name = kubernetes_secret.monocle_token.metadata.0.name
            items {
              key  = "monocle-token"
              path = "monocle.token"
            }
            items {
              key  = "monocle-properties"
              path = "monocle.properties"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "monocle_gateway_service" {
  metadata {
    name      = "monocle-gateway-service"
    namespace = kubernetes_namespace.monocle.metadata.0.name
    annotations = {
      "metallb.universe.tf/ip-allocated-from-pool" = "metallb-ip-pool"
      "metallb.universe.tf/loadBalancerIPs"        = var.monocle_gateway_ip_address
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "monocle-gateway"
    }

    port {
      port        = 443
      target_port = 443
      protocol    = "TCP"
      name        = "ui"
    }

    port {
      port        = 8555
      target_port = 8555
      protocol    = "TCP"
      name        = "rtsp"
    }

    port {
      port        = 8554
      target_port = 8554
      protocol    = "TCP"
      name        = "proxy"
    }

    type                    = "LoadBalancer"
    external_traffic_policy = "Local"
  }
}

