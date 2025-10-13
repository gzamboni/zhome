# Create namespace for DNS updater
resource "kubernetes_namespace" "cloudflare_dns_updater" {
  metadata {
    name = var.namespace
  }
}

# Create secret for Cloudflare credentials
resource "kubernetes_secret" "cloudflare_credentials" {
  metadata {
    name      = "cloudflare-credentials"
    namespace = kubernetes_namespace.cloudflare_dns_updater.metadata[0].name
  }

  data = {
    email   = var.cloudflare_email
    api_key = var.cloudflare_api_key
    zone_id = var.cloudflare_zone_id
  }
}

# Create ConfigMap for the update script
resource "kubernetes_config_map" "update_script" {
  metadata {
    name      = "dns-update-script"
    namespace = kubernetes_namespace.cloudflare_dns_updater.metadata[0].name
  }

  data = {
    "update-dns.sh" = <<-EOT
      #!/bin/sh
      set -e

      apk add --no-cache curl jq

      # Get the current external IP
      CURRENT_IP=$$(curl -s https://api.ipify.org)

      # Get the current DNS record
      RECORD_ID=$$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$${ZONE_ID}/dns_records?type=A&name=$${RECORD_NAME}.$${DOMAIN}" \
           -H "X-Auth-Email: $${CF_EMAIL}" \
           -H "X-Auth-Key: $${CF_API_KEY}" \
           -H "Content-Type: application/json" | jq -r '.result[0].id')

      if [ -z "$$RECORD_ID" ] || [ "$$RECORD_ID" = "null" ]; then
        echo "Error: Could not find DNS record $${RECORD_NAME}.$${DOMAIN}"
        exit 1
      fi

      # Get the current IP in the DNS record
      DNS_IP=$$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$${ZONE_ID}/dns_records/$${RECORD_ID}" \
           -H "X-Auth-Email: $${CF_EMAIL}" \
           -H "X-Auth-Key: $${CF_API_KEY}" \
           -H "Content-Type: application/json" | jq -r '.result.content')

      # Update the DNS record if the IP has changed
      if [ "$$CURRENT_IP" != "$$DNS_IP" ]; then
        echo "Updating $${RECORD_NAME}.$${DOMAIN} from $${DNS_IP} to $${CURRENT_IP}"

        curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$${ZONE_ID}/dns_records/$${RECORD_ID}" \
           -H "X-Auth-Email: $${CF_EMAIL}" \
           -H "X-Auth-Key: $${CF_API_KEY}" \
           -H "Content-Type: application/json" \
           --data "{\"type\":\"A\",\"name\":\"$${RECORD_NAME}\",\"content\":\"$${CURRENT_IP}\",\"ttl\":120,\"proxied\":false}" | jq
      else
        echo "IP address for $${RECORD_NAME}.$${DOMAIN} is already up to date ($${CURRENT_IP})"
      fi
    EOT
  }
}

# Create CronJob for Link 1
resource "kubernetes_cron_job_v1" "link1_dns_updater" {
  metadata {
    name      = "${var.link1_config.provider}-dns-updater"
    namespace = kubernetes_namespace.cloudflare_dns_updater.metadata[0].name
  }

  spec {
    schedule                      = var.schedule
    concurrency_policy            = "Replace"
    successful_jobs_history_limit = 3
    failed_jobs_history_limit     = 3

    job_template {
      metadata {
        name = "${var.link1_config.provider}-dns-updater"
      }

      spec {
        template {
          metadata {
            name = "${var.link1_config.provider}-dns-updater"
          }

          spec {
            host_network = true

            node_selector = {
              "kubernetes.io/hostname" = var.link1_config.node_name
            }

            container {
              name  = "dns-updater"
              image = "alpine:latest"

              command = ["/bin/sh", "-c"]
              args    = ["/scripts/update-dns.sh"]

              env {
                name = "CF_EMAIL"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.cloudflare_credentials.metadata[0].name
                    key  = "email"
                  }
                }
              }

              env {
                name = "CF_API_KEY"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.cloudflare_credentials.metadata[0].name
                    key  = "api_key"
                  }
                }
              }

              env {
                name = "ZONE_ID"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.cloudflare_credentials.metadata[0].name
                    key  = "zone_id"
                  }
                }
              }

              env {
                name  = "RECORD_NAME"
                value = var.link1_config.record_name
              }

              env {
                name  = "DOMAIN"
                value = var.domain
              }

              volume_mount {
                name       = "script-volume"
                mount_path = "/scripts"
              }

              resources {
                limits = {
                  cpu    = var.resources.limits.cpu
                  memory = var.resources.limits.memory
                }
                requests = {
                  cpu    = var.resources.requests.cpu
                  memory = var.resources.requests.memory
                }
              }
            }

            volume {
              name = "script-volume"
              config_map {
                name         = kubernetes_config_map.update_script.metadata[0].name
                default_mode = "0755"
              }
            }

            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}

# Create CronJob for Link 2
resource "kubernetes_cron_job_v1" "link2_dns_updater" {
  metadata {
    name      = "${var.link2_config.provider}-dns-updater"
    namespace = kubernetes_namespace.cloudflare_dns_updater.metadata[0].name
  }

  spec {
    schedule                      = var.schedule
    concurrency_policy            = "Replace"
    successful_jobs_history_limit = 3
    failed_jobs_history_limit     = 3

    job_template {
      metadata {
        name = "${var.link2_config.provider}-dns-updater"
      }

      spec {
        template {
          metadata {
            name = "${var.link2_config.provider}-dns-updater"
          }

          spec {
            host_network = true

            node_selector = {
              "kubernetes.io/hostname" = var.link2_config.node_name
            }

            container {
              name  = "dns-updater"
              image = "alpine:latest"

              command = ["/bin/sh", "-c"]
              args    = ["/scripts/update-dns.sh"]

              env {
                name = "CF_EMAIL"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.cloudflare_credentials.metadata[0].name
                    key  = "email"
                  }
                }
              }

              env {
                name = "CF_API_KEY"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.cloudflare_credentials.metadata[0].name
                    key  = "api_key"
                  }
                }
              }

              env {
                name = "ZONE_ID"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.cloudflare_credentials.metadata[0].name
                    key  = "zone_id"
                  }
                }
              }

              env {
                name  = "RECORD_NAME"
                value = var.link2_config.record_name
              }

              env {
                name  = "DOMAIN"
                value = var.domain
              }

              volume_mount {
                name       = "script-volume"
                mount_path = "/scripts"
              }

              resources {
                limits = {
                  cpu    = var.resources.limits.cpu
                  memory = var.resources.limits.memory
                }
                requests = {
                  cpu    = var.resources.requests.cpu
                  memory = var.resources.requests.memory
                }
              }
            }

            volume {
              name = "script-volume"
              config_map {
                name         = kubernetes_config_map.update_script.metadata[0].name
                default_mode = "0755"
              }
            }

            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}
