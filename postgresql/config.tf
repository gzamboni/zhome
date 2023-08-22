resource "kubernetes_secret" "postgres_admin_auth" {
  metadata {
    name      = "postgres-admin-auth"
    namespace = kubernetes_namespace.postgresql.metadata[0].name
  }
  data = {
    username = "postgres"
    password = "${var.postgresql_config.auth.postgresPassword}"
  }
}

resource "kubernetes_config_map" "postgresql_config" {
  metadata {
    name      = "postgresql-config"
    namespace = kubernetes_namespace.postgresql.metadata[0].name
    labels = {
      app = "postgresql"
    }
  }
  data = {
    POSTGRES_DB       = "postgres"
    POSTGRES_USER     = "${kubernetes_secret.postgres_admin_auth.data.username}"
    POSTGRES_PASSWORD = "${kubernetes_secret.postgres_admin_auth.data.password}"
    PGDATA            = "/var/lib/postgresql/data/db-files"
  }
}
