locals {
  smtp_config = var.default_smtp_config
}

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

  values = [<<-EOF
    alertmanager:
      config:
        global:
          smtp_hello: ${local.smtp_config.server.helo_name}
          smtp_from: ${local.smtp_config.email_config.from}
          smtp_smarthost: ${local.smtp_config.server.host}:${local.smtp_config.server.port}
          smtp_auth_username: ${local.smtp_config.auth.username}
          smtp_auth_password: ${local.smtp_config.auth.password}
          smtp_require_tls: ${local.smtp_config.server.port == 587 ? "true" : "false"}

      receivers:
      - name: default-receiver
        email_configs:
        - to: gzamboni@gmail.com
          send_resolved: true

      ingress:
        enabled: true
        annotations:
          kubernetes.io/ingress.class: traefik
        hosts:
        - host: alertmanager.${var.domain}
          paths:
          - path: /
            pathType: ImplementationSpecific

    serverFiles:
      alerting_rules.yml:
        groups:
        - name: k3s
          rules:
          - alert: LowDiskSpaceWarning
            expr: 100 * (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) < 25
            for: 1m
            labels:
              severity: warning
            annotations:
              summary: "Low disk space on {{ $labels.instance }}"
              description: "{{ $labels.instance }} has less than 25% disk space available."
          - alert: LowDiskSpaceCritical
            expr: 100 * (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) < 10
            for: 1m
            labels:
              severity: critical
            annotations:
              summary: "Low disk space on {{ $labels.instance }}"
              description: "{{ $labels.instance }} has less than 10% disk space available."
  EOF
  ]
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

