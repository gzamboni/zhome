# N8N Terraform Module for Kubernetes

This Terraform module deploys [n8n](https://n8n.io/) on a Kubernetes cluster. n8n is a workflow automation tool that allows you to connect various services and automate tasks.

## Features

- Deploys n8n in a dedicated namespace
- Configures persistent storage for n8n data
- Supports various database backends (SQLite, PostgreSQL, MySQL)
- Configurable resources (CPU, memory)
- Basic authentication support
- Exposes n8n via a LoadBalancer service with a dedicated IP

## Requirements

- Kubernetes cluster
- Terraform >= 0.13
- Kubernetes provider
- MetalLB or similar load balancer for IP allocation

## Usage

This module includes a `terraform.tfvars` file with example values for all variables. You can use this as a starting point and customize it for your environment.

```hcl
module "n8n" {
  source = "./n8n"

  n8n_ip_address = "192.168.1.100"  # Required: IP address for the n8n service

  # Optional parameters with defaults
  n8n_namespace         = "n8n"
  storage_class_name    = "longhorn-ssd"
  n8n_data_storage_size = "5Gi"
  n8n_image             = "n8nio/n8n:latest"
  n8n_replicas          = 1
  n8n_port              = 5678

  # Resource limits and requests
  n8n_resources_limits_cpu      = "1"
  n8n_resources_limits_memory   = "1Gi"
  n8n_resources_requests_cpu    = "250m"
  n8n_resources_requests_memory = "256Mi"

  # Optional: Security settings
  n8n_encryption_key     = "your-encryption-key"  # Recommended for production
  n8n_basic_auth_user    = "admin"                # Optional: Enable basic auth
  n8n_basic_auth_password = "password"            # Optional: Enable basic auth

  # Optional: External URL configuration
  n8n_webhook_url = "https://n8n.example.com"     # Optional: External webhook URL

  # Optional: Database configuration (defaults to SQLite)
  n8n_db_type     = "postgresdb"                  # Options: sqlite, postgresdb, mysqldb
  n8n_db_host     = "postgres-service"
  n8n_db_port     = 5432
  n8n_db_name     = "n8n"
  n8n_db_user     = "n8n"
  n8n_db_password = "password"

  # Optional: Timezone
  n8n_timezone    = "UTC"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| n8n_ip_address | IP address for the n8n service | string | n/a | yes |
| n8n_namespace | Kubernetes namespace for n8n | string | "n8n" | no |
| storage_class_name | Storage class name for persistent volumes | string | "longhorn-ssd" | no |
| n8n_data_storage_size | Size of the persistent volume for n8n data | string | "5Gi" | no |
| n8n_image | Docker image for n8n | string | "n8nio/n8n:latest" | no |
| n8n_replicas | Number of n8n replicas | number | 1 | no |
| n8n_port | Port for n8n service | number | 5678 | no |
| n8n_resources_limits_cpu | CPU limits for n8n | string | "1" | no |
| n8n_resources_limits_memory | Memory limits for n8n | string | "1Gi" | no |
| n8n_resources_requests_cpu | CPU requests for n8n | string | "250m" | no |
| n8n_resources_requests_memory | Memory requests for n8n | string | "256Mi" | no |
| n8n_encryption_key | Encryption key for n8n | string | "" | no |
| n8n_webhook_url | Webhook URL for n8n | string | "" | no |
| n8n_timezone | Timezone for n8n | string | "UTC" | no |
| n8n_basic_auth_user | Basic auth username for n8n | string | "" | no |
| n8n_basic_auth_password | Basic auth password for n8n | string | "" | no |
| n8n_db_type | Database type for n8n (sqlite, postgresdb, mysqldb) | string | "sqlite" | no |
| n8n_db_host | Database host for n8n | string | "" | no |
| n8n_db_port | Database port for n8n | number | 5432 | no |
| n8n_db_name | Database name for n8n | string | "n8n" | no |
| n8n_db_user | Database user for n8n | string | "n8n" | no |
| n8n_db_password | Database password for n8n | string | "" | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | The Kubernetes namespace where n8n is deployed |
| service_name | The name of the n8n service |
| ip_address | The IP address of the n8n service |
| url | The URL to access n8n |
| data_pvc_name | The name of the persistent volume claim for n8n data |

## Notes

- For production use, it's recommended to set an encryption key using the `n8n_encryption_key` variable.
- When using a database other than SQLite, make sure the database is accessible from the Kubernetes cluster.
- The module uses MetalLB annotations for IP allocation. Adjust as needed for your load balancer solution.
- The deployment includes an init container and security context to ensure proper permissions for the n8n data directory. This prevents permission denied errors when n8n tries to write to its configuration files.
