locals {
  # Parse the CIDR into network address and prefix length
  network_address = split("/", var.local_network_cidr)[0]
  prefix_length   = tonumber(split("/", var.local_network_cidr)[1])

  # Calculate how many octets are in the network portion based on prefix length
  network_octets = ceil(local.prefix_length / 8)

  # Extract the network portion octets
  network_portion = slice(split(".", local.network_address), 0, local.network_octets)

  # Reverse the octets and form the in-addr.arpa zone
  reverse_network_zone = "${join(".", reverse(local.network_portion))}.in-addr.arpa"
}

resource "kubernetes_namespace" "dns_namespace" {
  metadata {
    name = "dns"
  }
}

# Generate a secret for DNS updates
resource "random_string" "dns_secret" {
  length  = 32
  special = false
  upper   = true
  lower   = true
}

resource "kubernetes_secret" "dns_secret" {
  metadata {
    name      = "dns-secret"
    namespace = kubernetes_namespace.dns_namespace.metadata[0].name
  }

  data = {
    "dns_secret_key" = md5(random_string.dns_secret.result)
  }
}

resource "kubernetes_config_map" "bind_config" {
  metadata {
    name      = "bind-config"
    namespace = kubernetes_namespace.dns_namespace.metadata[0].name
  }

  data = {
    "named.conf" = <<-EOF
      // This file is managed by Terraform. Do not edit.
      include "/etc/bind/named.conf.keys";
      include "/etc/bind/named.conf.options";
      include "/etc/bind/named.conf.local";
      include "/etc/bind/named.conf.default-zones";
      include "/etc/bind/named.conf.control";
    EOF

    "named.conf.keys" = <<-EOF
      // This file is managed by Terraform. Do not edit.
      // Add TSIG keys here if needed for secure updates.
      key "${var.rndc_key_name}" {
          algorithm hmac-md5;
          secret "${base64encode(kubernetes_secret.dns_secret.data["dns_secret_key"])}";
      };
    EOF

    "named.conf.options" = <<-EOF
      # This file is managed by Terraform. Do not edit.
      options {
        directory "/var/cache/bind";

        forwarders {
          ${var.adblock_ip};
        };
        dnssec-validation auto;
        listen-on-v6 { any; };
        # IP addresses and network ranges allowed to query the DNS server:
        allow-query {
            127.0.0.1;
            ${var.local_network_cidr};
            10.0.0.0/8;  # Kubernetes pod network
        };

        # IP addresses and network ranges allowed to run recursive queries:
        # (Zones not served by this DNS server)
        allow-recursion {
            127.0.0.1;
            ${var.local_network_cidr};
            10.0.0.0/8;  # Kubernetes pod network
        };
        notify no;
        empty-zones-enable no;
        # Disable zone transfers
        allow-transfer {
            none;
        };
      };
    EOF

    "named.conf.local" = <<-EOF
      zone "${var.local_domain}" {
        type master;
        file "/etc/bind/db.${var.local_domain}";
        allow-update { key "${var.rndc_key_name}"; };
      };

      # Reverse DNS zone for local network
      zone "${local.reverse_network_zone}" {
        type master;
        file "/etc/bind/db.${local.reverse_network_zone}";
        allow-update { key "${var.rndc_key_name}"; };
      };

      # Localhost zone
      zone "localhost" {
        type master;
        file "/etc/bind/db.localhost";
        allow-update { none; };
      };

      # Reverse zone for localhost
      zone "0.0.127.in-addr.arpa" {
        type master;
        file "/etc/bind/db.127.0.0";
        allow-update { none; };
      };
    EOF

    "named.conf.control" = <<-EOF
      # controls {
      #     inet 127.0.0.1
      #     allow { key "${var.rndc_key_name}"; };
      # };
    EOF

    "named.conf.default-zones" = <<-EOF
      // This file is managed by Terraform. Do not edit.
      // Prime the server with knowledge of the root servers
      zone "." {
          type hint;
          file "/usr/share/dns/root.hints";
      };
    EOF

    "db.${var.local_domain}" = <<-EOF
      $TTL 604800
      @   IN  SOA ns1.${var.local_domain}. admin.${var.local_domain}. (
                  3         ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800 )   ; Negative Cache TTL
      ;
      @   IN  NS  ns1.${var.local_domain}.
      ns1 IN  A   ${var.fixed_ip}
    EOF

    # Reverse DNS zone file
    "db.${local.reverse_network_zone}" = <<-EOF
      $TTL 604800
      @   IN  SOA ns1.${var.local_domain}. admin.${var.local_domain}. (
                  3         ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800 )   ; Negative Cache TTL
      ;
      @   IN  NS  ns1.${var.local_domain}.

      ; PTR record for the DNS server itself
      ${element(split(".", var.fixed_ip), 3)}  IN  PTR  ns1.${var.local_domain}.
    EOF

    # Localhost zone file
    "db.localhost" = <<-EOF
      $TTL 604800
      @       IN      SOA     localhost. root.localhost. (
                                1         ; Serial
                           604800         ; Refresh
                            86400         ; Retry
                          2419200         ; Expire
                           604800 )       ; Negative Cache TTL
      ;
      @       IN      NS      localhost.
      @       IN      A       127.0.0.1
      @       IN      AAAA    ::1
    EOF

    # Reverse zone file for localhost
    "db.127.0.0" = <<-EOF
      $TTL 604800
      @       IN      SOA     localhost. root.localhost. (
                                1         ; Serial
                           604800         ; Refresh
                            86400         ; Retry
                          2419200         ; Expire
                           604800 )       ; Negative Cache TTL
      ;
      @       IN      NS      localhost.
      1       IN      PTR     localhost.
    EOF
  }

  depends_on = [kubernetes_secret.dns_secret]
}

resource "kubernetes_deployment" "bind_deployment" {
  metadata {
    name      = "bind9"
    namespace = kubernetes_namespace.dns_namespace.metadata[0].name
    labels = {
      "app" = "bind9"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app" = "bind9"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "bind9"
        }
      }

      spec {
        container {
          name  = "bind9"
          image = "ubuntu/bind9:latest"

          volume_mount {
            name       = "config-volume"
            mount_path = "/etc/bind"
          }

          port {
            container_port = 53
            name           = "dns"
            protocol       = "UDP"
          }

          port {
            container_port = 53
            name           = "dns-tcp"
            protocol       = "TCP"
          }
        }

        volume {
          name = "config-volume"

          config_map {
            name = kubernetes_config_map.bind_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "bind_service" {
  metadata {
    name      = "bind9"
    namespace = kubernetes_namespace.dns_namespace.metadata[0].name
    annotations = {
      "metallb.universe.tf/ip-allocated-from-pool" = "metallb-ip-pool"
    }
  }

  spec {
    selector = {
      app = kubernetes_deployment.bind_deployment.metadata[0].labels.app
    }

    port {
      name        = "dns"
      port        = 53
      target_port = "dns"
      protocol    = "UDP"
    }

    port {
      name        = "dns-tcp"
      port        = 53
      target_port = "dns-tcp"
      protocol    = "TCP"
    }

    type                    = "LoadBalancer"
    load_balancer_ip        = var.fixed_ip
    external_traffic_policy = "Local"
  }
}
