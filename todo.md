# AdGuard Module Refactoring Plan

## Goal
Refactor the existing `adguard` module into two separate modules (`adguard-install` and `adguard-config`) to resolve dependency issues and ensure proper initial configuration.

## Architecture
*   **Root Module**: Calls `adguard-install` first, then `adguard-config`.
*   **AdGuard Install Module**:
    *   Responsible for Kubernetes resources (Namespace, PVC, Deployment, Service, ConfigMap).
    *   Bootstraps the `AdGuardHome.yaml` configuration.
    *   Hashes the plain-text password from variables for the initial config.
    *   **Inputs**: Kubernetes config, Admin/API passwords (plain), Storage settings.
    *   **Outputs**: LoadBalancer IP.
*   **AdGuard Config Module**:
    *   Responsible for AdGuard application configuration (Filters, Rewrites, DNS settings) using the Terraform Provider.
    *   **Inputs**: AdGuard IP (from Install module), Admin password (plain, for API auth).

## Steps

1.  **Preparation**
    *   [ ] Add `bcrypt` provider to root `providers.tf` or module-level requirements to support password hashing.

2.  **Create `adguard-install` Module**
    *   [ ] Create directory `adguard/install`.
    *   [ ] Create `adguard/install/main.tf`: Move Kubernetes resources (Deployment, Service, PVC, Namespace) here.
    *   [ ] Create `adguard/install/configmap.tf`: Move ConfigMap definition here.
        *   *Logic*: Use `bcrypt` to hash `var.admin_password` and `var.api_password` before injecting into `AdGuardHome.yaml`.
    *   [ ] Create `adguard/install/variables.tf`: Define necessary variables.
    *   [ ] Create `adguard/install/outputs.tf`: Output the `load_balancer_ip`.
    *   [ ] Create `adguard/install/versions.tf`: Define provider requirements (Kubernetes, Bcrypt).

3.  **Create `adguard-config` Module**
    *   [ ] Create directory `adguard/config`.
    *   [ ] Create `adguard/config/main.tf`: Configure `adguard` provider here.
    *   [ ] Move `adguard/config.tf`, `adguard/filtering.tf`, `adguard/rewrites.tf` content to this module.
    *   [ ] Create `adguard/config/variables.tf`: Define inputs (including `adguard_ip` and passwords).
    *   [ ] Create `adguard/config/versions.tf`: Define provider requirements (AdGuard).

4.  **Root Module Integration**
    *   [ ] Modify root `main.tf`:
        *   Instantiate `module "adguard_install"`.
        *   Instantiate `module "adguard_config"`.
        *   Pass `module.adguard_install.adguard_ip` to `module.adguard_config`.
        *   Pass passwords from `var.adguard_config` to both modules.

5.  **Cleanup**
    *   [ ] Remove old files in `adguard/` root (`main.tf`, `config.tf`, etc.) once content is moved.

## Verification
*   Review `terraform plan` output (simulated) to ensure dependencies are correct.
