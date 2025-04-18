# ArgoCD Terraform Module for Kubernetes

This Terraform module deploys [ArgoCD](https://argoproj.github.io/argo-cd/) on a Kubernetes cluster. ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes.

## Features

- Deploys ArgoCD in a dedicated namespace
- Configures ArgoCD server, repo server, and application controller
- Supports high availability mode
- Configurable resources (CPU, memory)
- Admin password configuration
- Git repository configuration
- ArgoCD project creation
- Exposes ArgoCD via a LoadBalancer service with a dedicated IP

## Requirements

- Kubernetes cluster
- Terraform >= 0.13
- Kubernetes provider
- Helm provider
- Kubectl provider
- MetalLB or similar load balancer for IP allocation

## Usage

This module includes a `terraform.tfvars` file with example values for all variables. You can use this as a starting point and customize it for your environment.

```hcl
module "argocd" {
  source = "./argocd"

  argocd_ip_address = "192.168.1.100"  # Required: IP address for the ArgoCD service

  # Optional parameters with defaults
  argocd_namespace         = "argocd"
  storage_class_name       = "longhorn-ssd"
  argocd_chart_version     = "5.46.7"
  argocd_server_port       = 80
  argocd_repo_server_port  = 8081

  # Resource limits and requests
  argocd_resources_limits_cpu      = "1"
  argocd_resources_limits_memory   = "1Gi"
  argocd_resources_requests_cpu    = "250m"
  argocd_resources_requests_memory = "256Mi"

  # Optional: Security settings
  argocd_admin_password = "your-secure-password"  # Recommended for production
  argocd_insecure       = false
  argocd_ha_enabled     = false
  argocd_dex_enabled    = false

  # Optional: Git repositories configuration
  argocd_repositories = [
    {
      name     = "example-repo"
      url      = "https://github.com/example/repo.git"
      username = "git-user"      # Optional
      password = "git-password"  # Optional
    }
  ]

  # Optional: ArgoCD projects configuration
  argocd_projects = [
    {
      name        = "default"
      description = "Default project"
      source_repos = ["*"]
      destinations = [
        {
          server    = "https://kubernetes.default.svc"
          namespace = "*"
        }
      ]
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| argocd_ip_address | IP address for the ArgoCD service | string | n/a | yes |
| argocd_namespace | Kubernetes namespace for ArgoCD | string | "argocd" | no |
| storage_class_name | Storage class name for persistent volumes | string | "longhorn-ssd" | no |
| argocd_chart_version | Helm chart version for ArgoCD | string | "5.46.7" | no |
| argocd_server_port | Port for ArgoCD server service | number | 80 | no |
| argocd_repo_server_port | Port for ArgoCD repo server service | number | 8081 | no |
| argocd_resources_limits_cpu | CPU limits for ArgoCD server | string | "1" | no |
| argocd_resources_limits_memory | Memory limits for ArgoCD server | string | "1Gi" | no |
| argocd_resources_requests_cpu | CPU requests for ArgoCD server | string | "250m" | no |
| argocd_resources_requests_memory | Memory requests for ArgoCD server | string | "256Mi" | no |
| argocd_admin_password | Admin password for ArgoCD | string | "" | no |
| argocd_insecure | Disable TLS on the ArgoCD API server | bool | false | no |
| argocd_ha_enabled | Enable high availability mode for ArgoCD | bool | false | no |
| argocd_server_replicas | Number of ArgoCD server replicas | number | 1 | no |
| argocd_repo_server_replicas | Number of ArgoCD repo server replicas | number | 1 | no |
| argocd_application_controller_replicas | Number of ArgoCD application controller replicas | number | 1 | no |
| argocd_dex_enabled | Enable Dex for SSO integration | bool | false | no |
| argocd_repositories | Git repositories to configure in ArgoCD | list(object) | [] | no |
| argocd_projects | ArgoCD projects to create | list(object) | [] | no |
| kubeconfig_path | Path to kubeconfig file | string | "~/.kube/config" | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | The Kubernetes namespace where ArgoCD is deployed |
| server_service_name | The name of the ArgoCD server service |
| ip_address | The IP address of the ArgoCD server service |
| url | The URL to access ArgoCD UI |
| api_url | The URL to access ArgoCD API |
| repo_server_service_name | The name of the ArgoCD repo server service |
| application_controller_service_name | The name of the ArgoCD application controller service |
| projects | The ArgoCD projects created |
| repositories | The Git repositories configured in ArgoCD |

## Notes

- For production use, it's recommended to set a secure admin password using the `argocd_admin_password` variable.
- The default username for ArgoCD is `admin`.
- The module uses MetalLB annotations for IP allocation. Adjust as needed for your load balancer solution.
- By default, ArgoCD is deployed with a single replica for each component. For production environments, consider enabling high availability mode by setting `argocd_ha_enabled` to `true` and increasing the number of replicas.
- When using the `argocd_repositories` variable to configure Git repositories, sensitive information like passwords and SSH keys will be stored in the Terraform state. Consider using a remote state with encryption.
- For SSO integration, enable Dex by setting `argocd_dex_enabled` to `true` and configure it according to your needs.

## Accessing ArgoCD

After deploying ArgoCD, you can access the UI at the URL provided in the `url` output. The default username is `admin` and the password is the one you set in the `argocd_admin_password` variable. If you didn't set a password, ArgoCD will generate a random one that you can retrieve using:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## ArgoCD CLI

You can also interact with ArgoCD using the CLI. First, install the ArgoCD CLI:

```bash
# For macOS
brew install argocd

# For Linux
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

Then, log in to ArgoCD:

```bash
argocd login <argocd-server-ip>
```

## GitOps Workflow

ArgoCD follows the GitOps pattern where the desired state of your applications is stored in Git. To deploy an application using ArgoCD:

1. Create a Git repository with your Kubernetes manifests
2. Configure the repository in ArgoCD using the `argocd_repositories` variable
3. Create an ArgoCD Application that points to the repository and specifies the target cluster and namespace
4. ArgoCD will automatically sync the application state with the desired state in Git

For more information on using ArgoCD, refer to the [official documentation](https://argo-cd.readthedocs.io/en/stable/).
