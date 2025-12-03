# AdGuard Home Module

This module deploys and configures AdGuard Home on a Kubernetes cluster. It is split into two sub-modules to handle the dependency chain properly:

1. **Install Module**: Deploys the Kubernetes resources (Namespace, PVCs, Deployment, Service, ConfigMap)
2. **Config Module**: Configures AdGuard Home using the Terraform provider (DNS settings, filters, rewrites)

## Usage

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
module "adguard_config" {
  source         = "./adguard/config"
  adguard_ip     = module.adguard_install.adguard_ip
  admin_password = var.adguard_config.admin.token
  filters        = var.adguard_config.filter_list
  rewrites       = var.adguard_config.rewrites
  user_rules     = var.adguard_config.user_rules
  depends_on     = [module.adguard_install]
}
```

## Modules

### Install Module

The install module handles the deployment of AdGuard Home on Kubernetes. It creates:

- Kubernetes namespace
- Persistent Volume Claims for configuration and work directories
- Deployment with the AdGuard Home container
- Service with LoadBalancer type
- ConfigMap with initial AdGuard Home configuration

The module uses bcrypt to hash the admin and API passwords for secure storage in the ConfigMap.

### Config Module

The config module uses the AdGuard Home Terraform provider to configure:

- DNS settings
- Filtering settings
- DNS rewrites
- User rules

This module depends on the install module and will only run after the AdGuard Home instance is up and running.

## Variables

See the `variables.tf` files in each module for details on the required and optional variables.
