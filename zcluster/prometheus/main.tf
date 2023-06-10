resource "helm_release" "prometheus" {
  name             = "prometheus"
  namespace        = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  version          = "22.6.0"
  wait             = true
  create_namespace = true

  set {
    name  = "server.persistentVolume.enabled"
    value = "true"
  }
  set {
    name  = "server.persistentVolume.size"
    value = "10Gi"
  }
  set {
    name  = "server.persistentVolume.storageClass"
    value = "longhorn-external"
  }
  set {
    name  = "server.persistentVolume.accessModes[0]"
    value = "ReadWriteOnce"
  }
  set {
    name  = "server.ingress.enabled"
    value = "true"
  }
  set {
    name  = "server.ingress.hosts[0]"
    value = "prometheus.${var.domain}"
  }
  set {
    name  = "server.resources.requests.memory"
    value = "1Gi"
  }
  set {
    name  = "server.resources.requests.cpu"
    value = "500m"
  }
  set {
    name  = "server.resources.limits.memory"
    value = "2Gi"
  }
  set {
    name  = "server.resources.limits.cpu"
    value = "1"
  }
  set {
    name  = "alertmanager.enabled"
    value = "true"
  }
  set {
    name  = "alertmanager.persistentVolume.enabled"
    value = "true"
  }
  set {
    name  = "alertmanager.persistentVolume.size"
    value = "5Gi"
  }
  set {
    name  = "alertmanager.persistentVolume.storageClass"
    value = "longhorn-external"
  }
}


resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = "prometheus"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"

  wait             = false
  create_namespace = true

  values = [
    file("${path.module}/values/grafana.yaml"),
  ]
  depends_on = [helm_release.prometheus]
}
