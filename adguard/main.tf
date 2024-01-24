terraform {
  required_version = ">=0.13"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }
    adguard = {
      source  = "gmichels/adguard"
      version = "1.1.5"
    }
  }
}


resource "kubernetes_namespace" "adguard" {
  metadata {
    name = "adguard"
  }
}

resource "kubernetes_persistent_volume_claim" "adguard_pvc" {
  metadata {
    name      = "adguard-pvc"
    namespace = kubernetes_namespace.adguard.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    storage_class_name = "longhorn-nvme"
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
                name = "adguard-config"
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
            mount_path = "/opt/adguardhome/work"
            name       = "adguard-data"
          }
        }
        volume {
          name = "adguard-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.adguard_pvc.metadata.0.name
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
    rlimit_nofile: 0
    rlimit_nproc: 0
    log_file: ""
    log_syslog: false
    log_syslog_srv: ""
    pid_file: ""
    verbose: false
    users:
      - name: "admin"
        password: "${var.admin_token}"

      - name: "api"
        password: "${var.api_password}"
    EOF
  }
}



