terraform {
  required_version = ">=0.13"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }
    bcrypt = {
      source  = "viktorradnai/bcrypt"
      version = "0.1.2"
    }
  }
}

resource "bcrypt_hash" "admin_password" {
  cleartext = var.admin_password
  cost      = 10
}

resource "bcrypt_hash" "api_password" {
  cleartext = var.api_password
  cost      = 10
}

resource "kubernetes_namespace" "adguard" {
  metadata {
    name = "adguard"
  }
}

resource "kubernetes_persistent_volume_claim" "adguard_conf_pvc" {
  metadata {
    name      = "adguard-conf-pvc"
    namespace = kubernetes_namespace.adguard.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    storage_class_name = "longhorn"
  }
}

resource "kubernetes_persistent_volume_claim" "adguard_work_pvc" {
  metadata {
    name      = "adguard-work-pvc"
    namespace = kubernetes_namespace.adguard.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    storage_class_name = "longhorn"
  }
}

resource "kubernetes_deployment" "adguard" {
  metadata {
    name      = "adguard-deployment"
    namespace = kubernetes_namespace.adguard.metadata.0.name
    labels = {
      "app.kubernetes.io/name" = "adguard"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "adguard"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "adguard"
          "app"                    = "adguard"
        }
      }
      spec {
        container {
          name  = "adguard"
          image = "adguard/adguardhome:latest"
          env {
            name = "AGH_CONFIG"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.adguard_config.metadata[0].name
                key  = "AdGuardHome.yaml"
              }
            }
          }
          port {
            container_port = 80
            name           = "ui"
            protocol       = "TCP"
          }
          port {
            container_port = 3000
            name           = "ui-setup"
            protocol       = "TCP"
          }
          port {
            container_port = 53
            name           = "dns-tcp"
            protocol       = "TCP"
          }
          port {
            container_port = 53
            name           = "dns-udp"
            protocol       = "UDP"
          }
          volume_mount {
            mount_path = "/opt/adguardhome/conf"
            name       = "adguard-conf-data"
          }
          volume_mount {
            mount_path = "/opt/adguardhome/work"
            name       = "adguard-work-data"
          }
        }
        volume {
          name = "adguard-conf-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.adguard_conf_pvc.metadata.0.name
          }
        }
        volume {
          name = "adguard-work-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.adguard_work_pvc.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "adguard" {
  metadata {
    name      = "adguard-service"
    namespace = kubernetes_namespace.adguard.metadata.0.name
    annotations = {
      "metallb.universe.tf/ip-allocated-from-pool" = "metallb-ip-pool"
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "adguard"
    }
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
      name        = "ui"
    }
    port {
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
      name        = "ui-setup"
    }
    port {
      port        = 53
      target_port = 53
      protocol    = "TCP"
      name        = "dns-tcp"
    }
    port {
      port        = 53
      target_port = 53
      protocol    = "UDP"
      name        = "dns-udp"
    }
    type                    = "LoadBalancer"
    load_balancer_ip        = var.adguard_ip
    external_traffic_policy = "Local"
  }
}

resource "kubernetes_config_map_v1" "adguard_config" {
  metadata {
    name      = "adguard-config"
    namespace = kubernetes_namespace.adguard.metadata.0.name
  }
  data = {
    "AdGuardHome.yaml" = <<EOF
    bind_host: 0.0.0.0
    bind_port: 3000
    language: "en"
    verbose: false
    users:
      - name: "admin"
        password: "${bcrypt_hash.admin_password.id}"

      - name: "api"
        password: "${bcrypt_hash.api_password.id}"
    EOF
  }
}
