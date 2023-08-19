resource "kubernetes_namespace" "flowise_namespace" {
  count = var.flowise_config.enabled ? 1 : 0
  metadata {
    name = "flowise"
  }
}

resource "postgresql_role" "flowise_db_user" {
  count      = var.flowise_config.database.enabled ? 1 : 0
  name       = var.flowise_config.database.username
  login      = true
  password   = var.flowise_config.database.password
  depends_on = [helm_release.postgresql]
}


resource "postgresql_database" "flowise_db" {
  count      = var.flowise_config.database.enabled ? 1 : 0
  name       = var.flowise_config.database.database
  depends_on = [postgresql_role.flowise_db_user]
}

resource "helm_release" "flowise" {
  count      = var.flowise_config.enabled ? 1 : 0
  name       = "flowise"
  repository = "https://cowboysysop.github.io/charts/"
  chart      = "flowise"
  namespace  = kubernetes_namespace.flowise_namespace[count.index].metadata[0].name
  depends_on = [
    kubernetes_namespace.flowise_namespace,
    helm_release.postgresql,
    postgresql_database.flowise_db
  ]
  cleanup_on_fail = true

  set {
    name  = "image.repository"
    value = "cowboysysop/flowise"
  }

  set {
    name  = "image.tag"
    value = "latest"
  }

  set {
    name  = "image.pullPolicy"
    value = "Always"
  }

  set {
    name  = "ingress.enabled"
    value = var.flowise_config.ingress.enabled
  }

  set {
    name  = "ingress.hosts[0]"
    value = var.flowise_config.ingress.hosts.internal_hostname
  }

  set {
    name  = "ingress.hosts[0]"
    value = var.flowise_config.ingress.hosts.external_hostname
  }

  set {
    name  = "ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "traefik"
  }

  set {
    name  = "persistence.accessModes[0]"
    value = "ReadWriteOnce"
  }

  set {
    name  = "persistence.size"
    value = "10Gi"
  }

  set {
    name  = "persistence.storageClassName"
    value = "longhorn-ssd"
  }

  set {
    name  = "config.username"
    value = var.flowise_config.auth.username
  }

  set {
    name  = "config.password"
    value = var.flowise_config.auth.password
  }

  set {
    name  = "config.passphrase"
    value = var.flowise_config.auth.passphrase
  }

  set {
    name  = "externalPostgresql.enabled"
    value = var.flowise_config.database.enabled
  }

  dynamic "set" {
    for_each = var.flowise_config.database.enabled ? [var.flowise_config.database] : []
    content {
      name  = "externalPostgresql.host"
      value = set.value.host
    }
  }

  dynamic "set" {
    for_each = var.flowise_config.database.enabled ? [var.flowise_config.database] : []
    content {
      name  = "externalPostgresql.port"
      value = set.value.port
    }
  }

  dynamic "set" {
    for_each = var.flowise_config.database.enabled ? [var.flowise_config.database] : []
    content {
      name  = "externalPostgresql.database"
      value = set.value.database
    }
  }

  dynamic "set" {
    for_each = var.flowise_config.database.enabled ? [var.flowise_config.database] : []
    content {
      name  = "externalPostgresql.username"
      value = set.value.username
    }
  }

  dynamic "set" {
    for_each = var.flowise_config.database.enabled ? [var.flowise_config.database] : []
    content {
      name  = "externalPostgresql.password"
      value = set.value.password
    }
  }
}
