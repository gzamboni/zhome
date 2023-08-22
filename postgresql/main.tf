terraform {
  required_version = ">=0.13"
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.10.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.20.0"
    }
  }
}

resource "kubernetes_namespace" "postgresql" {
  metadata {
    name = "postgresql"
  }
}

resource "kubernetes_deployment" "postgresql_deploy" {
  metadata {
    name      = "postgresql"
    namespace = kubernetes_namespace.postgresql.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "postgresql"
      }
    }
    template {
      metadata {
        labels = {
          app = "postgresql"
        }
      }
      spec {
        container {
          name              = "postgresql"
          image             = "postgres:latest"
          image_pull_policy = "IfNotPresent"
          port {
            container_port = 5432
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.postgresql_config.metadata.0.name
            }
          }
          volume_mount {
            mount_path = "/var/lib/postgresql/data"
            name       = kubernetes_persistent_volume.postgresql_pv.metadata.0.name
          }
        }
        volume {
          name = kubernetes_persistent_volume.postgresql_pv.metadata.0.name
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgresql_pvc.metadata.0.name
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_persistent_volume_claim.postgresql_pvc,
    kubernetes_persistent_volume.postgresql_pv,
    kubernetes_config_map.postgresql_config
  ]
}

resource "kubernetes_service" "postgresql_service" {
  metadata {
    name      = "postgresql"
    namespace = kubernetes_namespace.postgresql.metadata[0].name
    annotations = {
      "metallb.universe.tf/ip-allocated-from-pool" = "metallb-ip-pool"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.postgresql_deploy.spec[0].template[0].metadata[0].labels.app
    }
    type             = "LoadBalancer"
    session_affinity = "ClientIP"
    port {
      port        = 5432
      target_port = 5432
    }
  }
  depends_on = [kubernetes_deployment.postgresql_deploy]
}
