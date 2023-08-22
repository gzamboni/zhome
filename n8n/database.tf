resource "random_string" "n8n_db_password" {
  length           = 16
  special          = false
  override_special = "_%@"
}

resource "postgresql_role" "n8n_db_user" {
  name     = "n8n"
  login    = true
  password = random_string.n8n_db_password.result
}

resource "postgresql_database" "n8n_db" {
  name              = "n8n"
  owner             = postgresql_role.n8n_db_user.name
  template          = "template0"
  connection_limit  = -1
  allow_connections = true
}

resource "postgresql_grant" "n8n_admin" {
  database = postgresql_database.n8n_db.name
  role     = postgresql_role.n8n_db_user.name
  schema   = "public"
  privileges = [
    "ALL"
  ]
  object_type = "database"
}
