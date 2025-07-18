# Uptime Kuma Terraform Module

This module deploys Uptime Kuma to a Kubernetes cluster using Terraform.

## Features

- Deploys Uptime Kuma with persistent storage
- Configurable resource limits and requests
- Support for ingress configuration
- Support for LoadBalancer service type
- Health checks (liveness and readiness probes)
- Proper security context and permissions

## Usage

### Basic Usage (ClusterIP service)

```hcl
module "uptime_kuma" {
  source = "./uptime-kuma"

  namespace = "monitoring"
  timezone  = "America/Sao_Paulo"
}
```

### With Ingress

```hcl
module "uptime_kuma" {
  source = "./uptime-kuma"

  namespace       = "monitoring"
  timezone        = "America/Sao_Paulo"
  ingress_enabled = true
  ingress_hosts   = ["uptime.example.com"]
}
```

### With LoadBalancer

```hcl
module "uptime_kuma" {
  source = "./uptime-kuma"

  namespace        = "monitoring"
  timezone         = "America/Sao_Paulo"
  service_type     = "LoadBalancer"
  load_balancer_ip = "192.168.1.100"
}
```

### Full Configuration Example

```hcl
module "uptime_kuma" {
  source = "./uptime-kuma"

  namespace          = "monitoring"
  image              = "louislam/uptime-kuma:1"
  replicas           = 1
  port               = 3001
  storage_class_name = "longhorn"
  storage_size       = "5Gi"
  timezone           = "America/Sao_Paulo"

  service_type     = "LoadBalancer"
  load_balancer_ip = "192.168.1.100"

  ingress_enabled = true
  ingress_class   = "traefik"
  ingress_hosts   = ["uptime.example.com"]

  resources = {
    limits = {
      cpu    = "1000m"
      memory = "1Gi"
    }
    requests = {
      cpu    = "200m"
      memory = "256Mi"
    }
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| namespace | Kubernetes namespace for Uptime Kuma | `string` | `"uptime-kuma"` | no |
| image | Uptime Kuma Docker image | `string` | `"louislam/uptime-kuma:1"` | no |
| replicas | Number of replicas for Uptime Kuma deployment | `number` | `1` | no |
| port | Port for Uptime Kuma service | `number` | `3001` | no |
| storage_class_name | Storage class name for persistent volume | `string` | `"longhorn"` | no |
| storage_size | Storage size for Uptime Kuma data | `string` | `"2Gi"` | no |
| timezone | Timezone for Uptime Kuma | `string` | `"UTC"` | no |
| service_type | Kubernetes service type | `string` | `"ClusterIP"` | no |
| load_balancer_ip | Load balancer IP address | `string` | `""` | no |
| ingress_enabled | Enable ingress for Uptime Kuma | `bool` | `true` | no |
| ingress_class | Ingress class name | `string` | `"traefik"` | no |
| ingress_hosts | List of hostnames for ingress | `list(string)` | `[]` | no |
| resources | Resource limits and requests | `object` | See below | no |

### Default Resources

```hcl
resources = {
  limits = {
    cpu    = "500m"
    memory = "512Mi"
  }
  requests = {
    cpu    = "100m"
    memory = "128Mi"
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| namespace | Kubernetes namespace where Uptime Kuma is deployed |
| service_name | Name of the Uptime Kuma service |
| service_port | Port of the Uptime Kuma service |
| service_type | Type of the Uptime Kuma service |
| load_balancer_ip | Load balancer IP address (if applicable) |
| ingress_hosts | Ingress hostnames for Uptime Kuma |
| deployment_name | Name of the Uptime Kuma deployment |
| pvc_name | Name of the persistent volume claim |

## Requirements

- Terraform >= 0.13
- Kubernetes provider >= 2.20.0
- A running Kubernetes cluster
- Storage class (default: longhorn)

## Notes

- Uptime Kuma runs as user ID 1000 for security
- Data is persisted using a PersistentVolumeClaim
- Health checks are configured for both liveness and readiness
- The service supports ClusterIP, NodePort, and LoadBalancer types
- Ingress can be configured with custom hostnames and ingress class
