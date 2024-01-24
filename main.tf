module "zcluster" {
  source               = "./zcluster"
  cluster_name         = var.k3s_config.cluster_name
  local_domain         = var.k3s_config.local_domain
  node_ssh_key         = file("~/.ssh/id_rsa.pub")
  nodes                = var.k3s_config.nodes
  node_users           = var.k3s_config.users
  metallb_address_pool = var.metallb_address_pool
  default_smtp_config  = var.default_smtp_config
  cifs_backup_user     = var.cifs_backup_user
  cifs_backup_password = var.cifs_backup_password
  cifs_backup_target   = var.cifs_backup_target
}

module "dyndns" {
  source                      = "./dyndns"
  google_dynamic_dns_username = var.google_dynamic_dns_username
  google_dynamic_dns_password = var.google_dynamic_dns_password
  google_dynamic_dns_fqdn     = var.google_dynamic_dns_fqdn
  depends_on                  = [module.zcluster]
}

module "zvault" {
  source               = "./vaultwarden"
  depends_on           = [module.zcluster]
  timezone             = var.vaultwarden_config.timezone
  ingress_hosts        = var.vaultwarden_config.ingress_hosts
  allow_signups        = var.vaultwarden_config.allow_signups
  domain_white_list    = var.vaultwarden_config.domain_white_list
  org_creation_users   = var.vaultwarden_config.org_creation_users
  default_vault_domain = var.vaultwarden_config.default_vault_domain
  smtp_config          = var.default_smtp_config
}

module "adguard" {
  source       = "./adguard"
  adguard_ip   = var.adguard_config.ip
  admin_token  = var.adguard_config.admin.token
  api_password = var.adguard_config.api.password
  filters      = var.adguard_config.filter_list
  rewrites     = var.adguard_config.rewrites
  user_rules   = var.adguard_config.user_rules
  depends_on   = [module.zcluster]
}
