resource "kubernetes_namespace" "qdrant_namespace" {
  metadata {
    name = "qdrant"
  }
}

resource "helm_release" "qdrant" {
  name            = "qdrant"
  repository      = "https://qdrant.github.io/qdrant-helm/"
  chart           = "qdrant"
  namespace       = kubernetes_namespace.qdrant_namespace.metadata[0].name
  cleanup_on_fail = true

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "traefik"
  }

  set {
    name  = "ingress.hosts[0].host"
    value = "qdrant.k3s.zhome.local"
  }

  set {
    name  = "ingress.hosts[0].paths[0].path"
    value = "/"
  }

  set {
    name  = "ingress.hosts[0].paths[0].pathType"
    value = "Prefix"
  }

  set {
    name  = "ingress.hosts[0].paths[0].servicePort"
    value = "6333"
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
}
