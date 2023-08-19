

resource "kubernetes_namespace" "postgresql" {
  count = var.postgresql_config.enabled ? 1 : 0
  metadata {
    name = "postgresql"
  }
}

resource "helm_release" "postgresql" {
  count           = var.postgresql_config.enabled ? 1 : 0
  name            = "postgresql"
  repository      = "https://charts.bitnami.com/bitnami"
  chart           = "postgresql"
  namespace       = kubernetes_namespace.postgresql[count.index].metadata[0].name
  cleanup_on_fail = true
  depends_on = [
    kubernetes_namespace.postgresql
  ]

  set {
    name  = "global.storageClass"
    value = "longhorn-ssd"
  }

  set {
    name  = "global.postgresql.auth.postgresPassword"
    value = var.postgresql_config.auth.postgresPassword
  }

  set {
    name  = "architecture"
    value = "standalone"
  }

}

