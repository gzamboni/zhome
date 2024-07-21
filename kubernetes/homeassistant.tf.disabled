resource "kubernetes_namespace" "homeassistant" {
  metadata {
    name = "homeassistant"
  }
}

resource "kubernetes_persistent_volume_claim" "homeassistant_data" {
  metadata {
    name      = "homeassistant-data"
    namespace = kubernetes_namespace.homeassistant.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    storage_class_name = "longhorn-ssd"
  }
}

resource "kubernetes_deployment" "homeassistant" {
  metadata {
    name      = "homeassistant"
    namespace = kubernetes_namespace.homeassistant.metadata.0.name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "homeassistant"
      }
    }

    template {
      metadata {
        labels = {
          app = "homeassistant"
        }
      }

      spec {
        volume {
          name = "homeassistant-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.homeassistant_data.metadata.0.name
          }
        }
        container {
          image = "homeassistant/home-assistant:latest"
          name  = "homeassistant"
          # command = ["/bin/sh", "-c"]
          # args    = ["wget -O - https://get.hacs.xyz | bash -"]
          port {
            container_port = 8123
            name           = "ui"
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
            mount_path = "/config"
            name       = "homeassistant-data"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "homeassistant_service" {
  metadata {
    name      = "homeassistant"
    namespace = kubernetes_namespace.homeassistant.metadata.0.name
  }

  spec {
    selector = {
      app = kubernetes_deployment.homeassistant.metadata.0.name
    }

    port {
      port        = 80
      target_port = kubernetes_deployment.homeassistant.spec.0.template.0.spec.0.container.0.port.0.container_port
    }
  }
}

resource "kubernetes_ingress_v1" "homeassistant_ingress" {
  wait_for_load_balancer = true
  metadata {
    name      = kubernetes_deployment.homeassistant.metadata.0.name
    namespace = kubernetes_namespace.homeassistant.metadata.0.name
  }
  spec {
    ingress_class_name = "traefik"
    rule {
      host = "ha.k3s.zhome.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.homeassistant_service.metadata.0.name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
