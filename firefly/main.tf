resource "helm_release" "firefly" {
  name = "firefly"

  repository       = "https://firefly-iii.github.io/kubernetes"
  chart            = "firefly-iii"
  version          = "1.5.0"
  create_namespace = true
  namespace        = "firefly"
  timeout          = 600 # Increase timeout to 10 minutes

  depends_on = [
    kubernetes_job.firefly_db_setup,
    kubernetes_secret.firefly_db_secret,
    kubernetes_namespace.firefly
  ]

  values = [
    yamlencode({
      persistence = {
        enabled = true
      }

      image = {
        repository = "fireflyiii/core"
        pullPolicy = "Always"
        tag        = "v6.3.0-beta.2"
      }

      cronjob = {
        enabled = true
        auth = {
          token = ""
        }
      }

      config = {
        env = {
          DB_CONNECTION    = "mysql"
          DB_PORT          = "3306"
          DB_DATABASE      = var.firefly_db_name
          DB_USERNAME      = var.firefly_db_user
          DB_HOST          = "${var.mysql_service_name}.${var.mysql_namespace}.svc.cluster.local"
          DEFAULT_LANGUAGE = "en_US"
          DEFAULT_LOCALE   = "equal"
          TZ               = "America/Sao_Paulo"
          TRUSTED_PROXIES  = "**"
        }
      }

      ingress = {
        enabled = false
      }

      resources = {
        requests = {
          cpu    = var.cpu_request
          memory = var.memory_request
        }
        limits = {
          memory = var.memory_limit
        }
      }
    })
  ]

  # No set parameters needed for ingress as it's disabled

  set_sensitive = [
    {
      name  = "secrets.env.APP_KEY"
      value = local.app_key
    },
    {
      name  = "secrets.env.APP_PASSWORD"
      value = var.firefly_app_password
    },
    {
      name  = "secrets.env.DB_PASSWORD"
      value = local.db_password
    },
    {
      name  = "cronjob.auth.token"
      value = random_password.token.result
    }
  ]
}

resource "random_password" "token" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+{}<>:?"
}

# Generate APP_KEY for Laravel encryption if not provided
resource "random_password" "app_key" {
  count   = var.firefly_app_key == "" ? 1 : 0
  length  = 32
  special = false # Use only alphanumeric to avoid base64 encoding issues
  upper   = true
  lower   = true
  numeric = true
}

# Create a random password for the Firefly database user if not provided
# Using simpler character set to avoid MySQL authentication issues
resource "random_password" "db_password" {
  count   = var.firefly_db_password == "" ? 1 : 0
  length  = 16
  special = false # Avoid special characters that can cause MySQL auth issues
  upper   = true
  lower   = true
  numeric = true
}

locals {
  # Generate base64 encoded APP_KEY in Laravel format
  app_key_raw = var.firefly_app_key == "" ? random_password.app_key[0].result : var.firefly_app_key
  app_key     = "base64:${base64encode(local.app_key_raw)}"
  db_password = var.firefly_db_password == "" ? random_password.db_password[0].result : var.firefly_db_password
}

# Create the Firefly database and user in MySQL
resource "kubernetes_job" "firefly_db_setup" {
  metadata {
    name      = "firefly-db-setup"
    namespace = var.mysql_namespace
  }

  spec {
    template {
      metadata {
        name = "firefly-db-setup"
      }
      spec {
        container {
          name    = "mysql-client"
          image   = "mysql:8.0"
          command = ["/bin/bash", "-c"]
          args = [<<-EOT
            echo "Waiting for MySQL to be ready..."
            until mysql -h ${var.mysql_service_name} -u root -p$MYSQL_ROOT_PASSWORD -e "SELECT 1"; do
              sleep 2
            done

            echo "Creating database ${var.firefly_db_name}..."
            mysql -h ${var.mysql_service_name} -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS ${var.firefly_db_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

            echo "Creating user ${var.firefly_db_user}..."
            mysql -h ${var.mysql_service_name} -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE USER IF NOT EXISTS '${var.firefly_db_user}'@'%' IDENTIFIED BY '${local.db_password}';"

            echo "Granting privileges..."
            mysql -h ${var.mysql_service_name} -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON ${var.firefly_db_name}.* TO '${var.firefly_db_user}'@'%';"

            echo "Flushing privileges..."
            mysql -h ${var.mysql_service_name} -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"

            echo "Database setup completed successfully."
          EOT
          ]

          env {
            name = "MYSQL_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = "${var.mysql_service_name}-secret"
                key  = "mysql-root-password"
              }
            }
          }
        }
        restart_policy = "OnFailure"
      }
    }
    backoff_limit = 4
  }

  wait_for_completion = true

  timeouts {
    create = "5m"
    update = "5m"
  }
}

# Create the firefly namespace explicitly
resource "kubernetes_namespace" "firefly" {
  metadata {
    name = "firefly"
  }
}

# Create a Kubernetes secret for the Firefly database password
resource "kubernetes_secret" "firefly_db_secret" {
  metadata {
    name      = "firefly-db-secret"
    namespace = "firefly"
  }

  data = {
    "DB_PASSWORD" = local.db_password
  }

  depends_on = [
    kubernetes_namespace.firefly
  ]
}

# Create a Kubernetes Ingress resource for Firefly III
resource "kubernetes_ingress_v1" "firefly" {
  metadata {
    name      = "firefly-ingress"
    namespace = "firefly"
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"
    }
  }

  spec {
    rule {
      host = var.fqdn
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "firefly-firefly-iii"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.firefly
  ]
}
