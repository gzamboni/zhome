resource "kubernetes_persistent_volume_claim" "postgresql_pvc" {
  metadata {
    name      = "postgresql-pvc"
    namespace = kubernetes_namespace.postgresql.metadata[0].name
    labels = {
      app = "postgresql"
    }
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "longhorn-ssd"
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

resource "kubernetes_persistent_volume" "postgresql_pv" {
  metadata {
    name = "postgresql-pv"
  }
  spec {
    capacity = {
      storage = "10Gi"
    }
    access_modes                     = ["ReadWriteOnce"]
    storage_class_name               = "longhorn-ssd"
    persistent_volume_reclaim_policy = "Retain"
    persistent_volume_source {
      csi {
        driver        = "driver.longhorn.io"
        volume_handle = kubernetes_persistent_volume_claim.postgresql_pvc.metadata.0.name
      }
    }
  }
}
