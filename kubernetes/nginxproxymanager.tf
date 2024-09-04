resource "kubernetes_namespace" "nginx_proxy_manager" {
  metadata {
    name = "nginx-proxy-manager"
  }
}

resource "kubernetes_persistent_volume_claim" "nginx_proxy_manager_data_pvc" {
  metadata {
    name      = "nginx-proxy-manager-data"
    namespace = kubernetes_namespace.nginx_proxy_manager.metadata.0.name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "2Gi"
      }
    }
    storage_class_name = "longhorn-ssd"
  }
}

resource "kubernetes_persistent_volume_claim" "nginx_proxy_manager_certs_pvc" {
  metadata {
    name      = "nginx-proxy-manager-certs"
    namespace = kubernetes_namespace.nginx_proxy_manager.metadata.0.name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "2Gi"
      }
    }
    storage_class_name = "longhorn-ssd"
  }
}

# Create all resources to deploy the Monocle Gateway service
resource "kubernetes_deployment" "nginx_proxy_manager_deployment" {
  metadata {
    name      = "nginx-proxy-manager"
    namespace = kubernetes_namespace.nginx_proxy_manager.metadata.0.name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "nginx-proxy-manager"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "nginx-proxy-manager"
          app                      = "nginx-proxy-manager"
        }
      }

      spec {
        container {
          name              = "nginx-proxy-manager"
          image             = "jc21/nginx-proxy-manager:latest"
          image_pull_policy = "Always"


          port {
            container_port = 443
            name           = "https"
            protocol       = "TCP"
          }

          port {
            container_port = 81
            name           = "mgnt"
            protocol       = "TCP"
          }

          port {
            container_port = 80
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
            name       = kubernetes_persistent_volume_claim.nginx_proxy_manager_data_pvc.metadata.0.name
            mount_path = "/data"
            read_only  = false
          }
          volume_mount {
            name       = kubernetes_persistent_volume_claim.nginx_proxy_manager_certs_pvc.metadata.0.name
            mount_path = "/etc/letsencrypt"
            read_only  = false
          }
        }
        volume {
          name = kubernetes_persistent_volume_claim.nginx_proxy_manager_data_pvc.metadata.0.name
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.nginx_proxy_manager_data_pvc.metadata.0.name
          }
        }
        volume {
          name = kubernetes_persistent_volume_claim.nginx_proxy_manager_certs_pvc.metadata.0.name
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.nginx_proxy_manager_certs_pvc.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx_proxy_manager_service" {
  metadata {
    name      = "nginx-proxy-manager-service"
    namespace = kubernetes_namespace.nginx_proxy_manager.metadata.0.name
    annotations = {
      "metallb.universe.tf/ip-allocated-from-pool" = "metallb-ip-pool"
      "metallb.universe.tf/loadBalancerIPs"        = var.nginx_proxy_manager_ip_address
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "nginx-proxy-manager"
    }

    port {
      port        = 443
      target_port = 443
      protocol    = "TCP"
      name        = "https"
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
      name        = "http"
    }

    port {
      port        = 81
      name        = "mgnt"
      target_port = 81
      protocol    = "TCP"
    }

    type                    = "LoadBalancer"
    external_traffic_policy = "Local"
  }
}

