resource "kubernetes_config_map" "n8n_config" {
  metadata {
    name      = "n8n-config"
    namespace = kubernetes_namespace.n8n.metadata[0].name
    labels = {
      app = "n8n"
    }
  }
  data = {
    NODE_ENV           = "production"
    GENERIC_TIMEZONE   = "America/Sao_Paulo"
    WEBHOOK_TUNNEL_URL = "https://wh.${var.n8n_config.domains.external}/" # well come back to this later
    # Database configurations
    DB_TYPE                = "postgresdb"
    DB_POSTGRESDB_USER     = postgresql_role.n8n_db_user.name
    DB_POSTGRESDB_DATABASE = postgresql_database.n8n_db.name
    DB_POSTGRESDB_HOST     = var.postgresql_cluster_host
    DB_POSTGRESDB_PORT     = "5432"
    N8N_PORT               = "5678"
    # Turn on basic auth
    N8N_BASIC_AUTH_ACTIVE = "true"
    N8N_BASIC_AUTH_USER   = var.n8n_config.auth.username
    VUE_APP_URL_BASE_API  = "http://n8n.${var.n8n_config.domains.internal}/"
    VUE_APP_PUBLIC_PATH   = "http://n8n.${var.n8n_config.domains.internal}/"
  }
  depends_on = [kubernetes_namespace.n8n]
}

resource "kubernetes_secret" "n8n_config" {
  metadata {
    name      = "n8n-config"
    namespace = kubernetes_namespace.n8n.metadata[0].name
    labels = {
      app = "n8n"
    }
  }
  data = {
    DB_POSTGRESDB_PASSWORD  = postgresql_role.n8n_db_user.password
    N8N_BASIC_AUTH_PASSWORD = var.n8n_config.auth.password
  }
  depends_on = [kubernetes_namespace.n8n]
}
