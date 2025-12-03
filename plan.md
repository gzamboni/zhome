# AdGuard Module Refactoring Plan

## Problem Statement

The original AdGuard module had a dependency issue: the AdGuard provider needed to connect to the AdGuard Home instance during the Terraform run, but the instance was being created in the same run. This caused the provider to fail to connect because the LoadBalancer IP wasn't reachable yet.

## Solution

We've refactored the AdGuard module into two separate modules:

1. **adguard/install**: Handles the Kubernetes resources (Namespace, PVCs, Deployment, Service, ConfigMap)
   - Uses bcrypt to hash the admin and API passwords for secure storage in the ConfigMap
   - Outputs the LoadBalancer IP for use by the config module

2. **adguard/config**: Handles the AdGuard configuration using the Terraform provider
   - Uses a null_resource with a local-exec provisioner to wait for the AdGuard Home instance to be ready
   - Configures DNS settings, filters, rewrites, and user rules
   - Depends on the install module

## Implementation Details

### Root Module Changes

```hcl
# 1. Install the Kubernetes resources
module "adguard_install" {
  source         = "./adguard/install"
  adguard_ip     = var.adguard_config.ip
  admin_password = var.adguard_config.admin.token
  api_password   = var.adguard_config.api.password
  depends_on     = [module.zcluster]
}

# 2. Configure AdGuard Home using the provider
# This module will only be applied during terraform apply, not during plan
module "adguard_config" {
  count          = var.adguard_config.enabled ? 1 : 0
  source         = "./adguard/config"
  adguard_ip     = module.adguard_install.adguard_ip
  admin_password = var.adguard_config.admin.token
  filters        = var.adguard_config.filter_list
  rewrites       = var.adguard_config.rewrites
  user_rules     = var.adguard_config.user_rules
  
  providers = {
    adguard = adguard
  }
}
```

### Install Module

The install module creates the Kubernetes resources and hashes the passwords:

```hcl
resource "bcrypt_hash" "admin_password" {
  cleartext = var.admin_password
  cost      = 10
}

resource "kubernetes_config_map_v1" "adguard_config" {
  # ...
  data = {
    "AdGuardHome.yaml" = <<EOF
    # ...
    users:
      - name: "admin"
        password: "${bcrypt_hash.admin_password.id}"
    # ...
    EOF
  }
}
```

### Config Module

The config module waits for the AdGuard Home instance to be ready before applying the configuration:

```hcl
resource "null_resource" "wait_for_adguard" {
  triggers = {
    adguard_ip = var.adguard_ip
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for AdGuard Home to be ready at ${var.adguard_ip}..."
      timeout=300
      counter=0
      while ! curl -s --connect-timeout 5 http://${var.adguard_ip}/control/status > /dev/null; do
        sleep 5
        counter=$((counter+5))
        if [ $counter -ge $timeout ]; then
          echo "Timeout waiting for AdGuard Home to be ready"
          exit 1
        fi
        echo "Still waiting for AdGuard Home to be ready... ($counter seconds elapsed)"
      done
      echo "AdGuard Home is ready!"
    EOT
  }
}

resource "adguard_config" "adguard_zhome" {
  depends_on = [null_resource.wait_for_adguard]
  # ...
}
```

## Benefits

1. **Proper Dependency Management**: The config module will only run after the install module has successfully created the AdGuard Home instance.
2. **Secure Password Handling**: Passwords are hashed using bcrypt before being stored in the ConfigMap.
3. **Improved Reliability**: The wait_for_adguard resource ensures that the AdGuard Home instance is ready before applying the configuration.
4. **Conditional Application**: The config module is only applied during terraform apply, not during plan, avoiding connection issues during planning.

## Usage

To use the refactored AdGuard module, simply include it in your Terraform configuration as shown in the root module changes above. The module will handle the rest, including waiting for the AdGuard Home instance to be ready before applying the configuration.
