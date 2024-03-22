resource "adguard_config" "adguard_zhome" {
  depends_on = [kubernetes_deployment.adguard]
  filtering = {
    enabled         = true
    update_interval = 1
  }

  safebrowsing = true

  safesearch = {
    enabled  = false
    services = ["bing", "youtube", "google"]
  }

  querylog = {
    enabled             = true
    anonymize_client_ip = false
    interval            = 8
  }

  stats = {
    enabled  = true
    interval = 168
  }

  # tls = {
  #   enabled           = false
  #   server_name       = "ZHome AdGuard Home"
  #   certificate_chain = "/opt/adguardhome/ssl/chain.crt"
  #   private_key       = "/opt/adguardhome/ssl/server.key"
  # }

  dns = {
    upstream_dns  = ["https://dns.cloudflare.com/dns-query", "https://dns.google/dns-query"]
    upstream_mode = "load_balance"
    bootstrap_dns = ["1.1.1.1", "1.0.0.1", "8.8.8.8", "8.8.4.4"]
    # local_ptr_upstreams        = []
    use_private_ptr_resolvers  = true
    resolve_clients            = true
    rate_limit_subnet_len_ipv4 = 24
    rate_limit_subnet_len_ipv6 = 56
    # rate_limit_whitelist       = []
    edns_cs_enabled    = false
    edns_cs_use_custom = false
    # edns_cs_custom_ip          = ""
    dnssec_enabled       = false
    blocking_mode        = "default"
    blocked_response_ttl = 10
    cache_size           = 4194304
    cache_ttl_min        = 0
    cache_ttl_max        = 0
    cache_optimistic     = false
    # allowed_clients      = []
    # disallowed_clients   = []
    blocked_hosts = [
      "version.bind",
      "id.server",
      "hostname.bind",
      "localhost.",
      "invalid"
    ]
  }
}
